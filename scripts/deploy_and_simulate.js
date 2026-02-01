import hre from "hardhat";

async function main() {
  console.log("🚀 Starting Common Protocol (Local Mode)...");
  
  const [deployer, user1] = await hre.ethers.getSigners();

  // ---------------------------------------------------------
  // 1. DEPLOY MOCK USDC
  // ---------------------------------------------------------
  const MockUSDC = await hre.ethers.getContractFactory("MockUSDC");
  const usdc = await MockUSDC.deploy(); 
  await usdc.waitForDeployment();
  const usdcAddr = await usdc.getAddress();
  
  const decimals = await usdc.decimals();
  console.log(`   > Mock USDC deployed: ${usdcAddr} (Decimals: ${decimals})`);

  // ---------------------------------------------------------
  // 2. DEPLOY GATE
  // ---------------------------------------------------------
  const CommonGate = await hre.ethers.getContractFactory("CommonGate");
  const gate = await CommonGate.deploy(deployer.address);
  await gate.waitForDeployment();
  const gateAddr = await gate.getAddress();
  console.log(`   > Gate deployed: ${gateAddr}`);

  // ---------------------------------------------------------
  // 3. DEPLOY VAULT (FIXED SECTION)
  // ---------------------------------------------------------
  const CommonVault = await hre.ethers.getContractFactory("CommonVault");
  
  // --- MISSING LINES RESTORED BELOW ---
  const vault = await CommonVault.deploy(usdcAddr);
  await vault.waitForDeployment();
  const vaultAddr = await vault.getAddress();
  console.log(`   > Vault deployed: ${vaultAddr}`);

  // --- NEW: Auto-Verify the Deployer (You) ---
  console.log("   > Auto-Verifying Deployer...");
  await vault.setVerification(deployer.address, true); 
  
  // Verify User1 for the simulation
  await vault.setVerification(user1.address, true);

  // ---------------------------------------------------------
  // 4. SIMULATION
  // ---------------------------------------------------------
  console.log("\n⚙️  Running Simulation...");

  // Mint Funds
  const mintAmount = hre.ethers.parseUnits("10000", decimals);
  await usdc.mint(user1.address, mintAmount);
  console.log(`     - Minted 10,000 USDC to User`);

  const depositAmount = hre.ethers.parseUnits("5000", decimals);
  await usdc.connect(user1).approve(vaultAddr, depositAmount);
  await vault.connect(user1).deposit(depositAmount, user1.address);
  console.log("     - User deposited 5,000 USDC");

  // ---------------------------------------------------------
  // 5. OUTPUT FOR FRONTEND
  // ---------------------------------------------------------
  console.log("\n✅ DEPLOYMENT COMPLETE. COPY THIS TO 'chains.ts':");
  console.log("---------------------------------------------------");
  console.log(`export const CHAINS = {`);
  console.log(`  LOCAL: 31337,`);
  console.log(`  WORLD_SEPOLIA: 4801`);
  console.log(`};`);
  console.log(``);
  console.log(`export const getChainConfig = (chainId: number) => {`);
  console.log(`  if (chainId === CHAINS.WORLD_SEPOLIA) return { name: "Sepolia", isDev: false, contracts: { usdc: "", vault: "", gate: "" } };`);
  console.log(`  return {`);
  console.log(`    name: "Localhost",`);
  console.log(`    isDev: true,`);
  console.log(`    contracts: {`);
  console.log(`      usdc: "${usdcAddr}",`);
  console.log(`      vault: "${vaultAddr}",`);
  console.log(`      gate: "${gateAddr}"`);
  console.log(`    }`);
  console.log(`  };`);
  console.log(`};`);
  console.log("---------------------------------------------------");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});