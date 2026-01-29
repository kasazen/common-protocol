const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("🚀 Bridge Deploy Starting...");

  // 1. Deploy USDC
  const MockUSDC = await hre.ethers.getContractFactory("MockUSDC");
  const usdc = await MockUSDC.deploy();
  await usdc.waitForDeployment();
  const usdcAddress = await usdc.getAddress();
  console.log(`✅ USDC: ${usdcAddress}`);

  // 2. Deploy Vault
  const CommonVault = await hre.ethers.getContractFactory("CommonVault");
  const vault = await CommonVault.deploy(usdcAddress);
  await vault.waitForDeployment();
  const vaultAddress = await vault.getAddress();
  console.log(`✅ Vault: ${vaultAddress}`);

  // 3. Fund Vault
  await usdc.approve(vaultAddress, hre.ethers.parseUnits("100000", 18));

  // 4. WRITE CONFIG TO FRONTEND
  // Note: We use path.resolve to correctly navigate up from scripts/
  const configPath = path.resolve(__dirname, "../../common-app/src/config.ts");
  
  const configContent = `
export const CONTRACT_ADDRESSES = {
  usdc: "${usdcAddress}",
  vault: "${vaultAddress}"
};

export const ABIS = {
  usdc: [
    "function name() view returns (string)",
    "function symbol() view returns (string)",
    "function balanceOf(address) view returns (uint256)",
    "function transfer(address to, uint amount)",
    "function approve(address spender, uint amount) returns (bool)",
    "function mint(address to, uint amount)"
  ],
  vault: [
    "function deposit(uint256 assets, address receiver) returns (uint256)",
    "function withdraw(uint256 assets, address receiver, address owner) returns (uint256)",
    "function convertToAssets(uint256 shares) view returns (uint256)",
    "function balanceOf(address) view returns (uint256)"
  ]
};
`;

  // Ensure directory exists
  const dir = path.dirname(configPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  fs.writeFileSync(configPath, configContent);
  console.log(`🌉 Config successfully written to: ${configPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
