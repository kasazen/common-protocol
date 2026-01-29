// scripts/simulate_yield.js
const hre = require("hardhat");

async function main() {
  const { ethers } = hre;
  
  // 1. Get the Deployer (The "Manager")
  const [deployer] = await ethers.getSigners();
  console.log(`👨‍🌾 Yield Farmer: ${deployer.address}`);

  // 2. Load Contracts (Using the addresses from your last deployment)
  // NOTE: If you redeploy, these update automatically if we query the network, 
  // but hardcoding for safety or using deployments file is better. 
  // For now, let's fetch strictly by the addresses you verified earlier.
  // UPDATE THESE IF YOU RE-DEPLOYED!
  const VAULT_ADDR = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; 
  const USDC_ADDR = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

  const vault = await ethers.getContractAt("CommonVault", VAULT_ADDR);
  const usdc = await ethers.getContractAt("MockUSDC", USDC_ADDR);

  console.log("🚜 Starting Yield Farming Simulation...");
  console.log("   (Press Ctrl+C to stop)");

  // 3. The Infinite Loop of Profit
  while (true) {
    try {
      // A. Mint "Profit" (10 USDC) from thin air
      const profit = ethers.parseUnits("10.0", 18);
      await usdc.mint(deployer.address, profit);

      // B. Send Profit directly to Vault (This increases share price!)
      // ERC4626 logic: totalAssets() goes up, totalSupply() stays same => Price goes up.
      await usdc.transfer(VAULT_ADDR, profit);

      // C. Update Vault Accounting (Updates APY stats)
      const tx = await vault.harvest(profit);
      await tx.wait();

      // D. Report
      const totalAssets = await vault.totalAssets();
      console.log(`💰 Harvested $10.00 USDC | Vault TVL: $${ethers.formatUnits(totalAssets, 18)}`);

      // E. Wait 5 seconds
      await new Promise(r => setTimeout(r, 5000));

    } catch (error) {
      console.error("❌ Harvest Failed:", error.message);
      break;
    }
  }
}

main();