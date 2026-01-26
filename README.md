# Veda Arctic: Human-Centric Yield Vault

Veda Arctic is a professional treasury management protocol built for **World Chain**. It leverages the **BoringVault** architecture to provide secure, Merkle-verified yield strategies while rewarding verified human users through a custom engagement engine.

## 🚀 Protocol Core
- **BoringVault:** Secure asset custody and management[cite: 375, 376].
- **Accountant:** Manages 25% performance fees and weighted APY calculations[cite: 333, 336, 339, 346].
- **Veda Fuel:** A points system rewarding DAU and long-term loyalty (2x boost after 30 days)[cite: 341, 342, 343].
- **Veda Lens:** Single-call API for mobile dashboards[cite: 350, 351, 352].

## 🛡️ Security
- **Merkle Manager:** All vault rebalances must match a pre-authorized Merkle root[cite: 325, 329, 330].
- **Decoders:** Logic-specific firewalls for Aave V3, Uniswap, and Across[cite: 386, 392, 402].
- **Share Lock:** 24-hour withdrawal lock to prevent MEV exploitation[cite: 362, 370].

## 🛠️ Developer Setup
\`\`\`bash
forge install
forge test --match-path test/DeployVerification.t.sol
\`\`\`
