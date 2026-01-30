const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // 1. Deploy Mock USDC
  const MockUSDC = await hre.ethers.getContractFactory("MockUSDC");
  const usdc = await MockUSDC.deploy();
  await usdc.waitForDeployment();
  const usdcAddress = await usdc.getAddress();
  console.log("MockUSDC deployed to:", usdcAddress);

  // 2. Deploy CommonVault
  const CommonVault = await hre.ethers.getContractFactory("CommonVault");
  const vault = await CommonVault.deploy(usdcAddress);
  await vault.waitForDeployment();
  const vaultAddress = await vault.getAddress();
  console.log("CommonVault deployed to:", vaultAddress);

  // 3. Export for Frontend (this saves you from manual copy-pasting)
  console.log("\n--- COPY THIS INTO common-app/src/config.ts ---");
  console.log(`export const CONTRACT_ADDRESSES = {`);
  console.log(`  usdc: "${usdcAddress}",`);
  console.log(`  vault: "${vaultAddress}"`);
  console.log(`};`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
