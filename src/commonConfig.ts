// commonConfig.ts
// Brand: COMMON
// Network: World Chain Sepolia
// Status: LIVE

export const COMMON_CONFIG = {
  chainId: 4801,
  networkName: "World Chain Sepolia",
  explorerUrl: "https://sepolia.worldscan.org",

  // The System
  contracts: {
    Vault: "0xB32d8f0587F3Bf7b76103983C16b49d9DE16AF1c",     // The Reserve
    Strategy: "0xb92Da60abb7b1B5A8c1d32E6b4E6aDa9191cBf4D",  // The Brain
    Gate: "0xf5b6C9182dae3656E5B4f0d941bE63eAd56Db82e",      // The Entry
    Window: "0x16C87cA1939e3bFDAD8C4157E0603e132F9E9701",    // The View
    Rates: "0x5963a9d8F1135794C8d6460c090b00a743F05edA",     // The Calculator
  },

  // Assets
  assets: {
    mockUsdc: "0xe64F7d7Fbb277cCBfC49DA56986b2B740a0Cb0DB",
  },

  // Website Text
  text: {
    brandName: "Common",
    vaultName: "Common Vault",
    pointsName: "Points",
    feedName: "Actions"
  }
};

// Simplified ABI
export const COMMON_ABI = {
  // The Window
  Window: [
    "function getDashboard(address user, address vault, address rates, address gate) external view returns (tuple(uint256 walletBalance, uint256 moneyInVault, uint256 apy, uint256 netApy, uint256 bonusMultiplier, uint256 points, bool isVerified, uint256 unlockTimer, uint256 safetyBuffer))"
  ],
  // The Strategy
  Strategy: [
    "event Pulse(string action, string rationale, uint256 timestamp)"
  ],
  // The Gate
  Gate: [
    "function deposit(address asset, uint256 amount) external returns (uint256)",
    "function withdraw(uint256 shares) external"
  ]
};
