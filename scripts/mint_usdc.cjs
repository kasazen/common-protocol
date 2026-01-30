const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  
  // These are the addresses from your last deployment
  const usdcAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  
  const MockUSDC = await hre.ethers.getContractAt("MockUSDC", usdcAddress);
  
  console.log("Minting 10,000 USDC to:", deployer.address);
  
  // Minting 10,000 with 18 decimals
  const mintAmount = hre.ethers.parseUnits("10000", 18);
  const tx = await MockUSDC.mint(deployer.address, mintAmount);
  await tx.wait();

  const balance = await MockUSDC.balanceOf(deployer.address);
  console.log("New Balance:", hre.ethers.formatUnits(balance, 18), "USDC");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
