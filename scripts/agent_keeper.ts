// common-protocol/scripts/agent_keeper.ts
import { ethers } from "hardhat";

async function main() {
  console.log("🤖 Autonomous Yield Agent Started...");
  
  // 1. CONFIGURATION
  // This must match the address where you deployed the Vault in your local hardhat node
  // If you aren't sure, look at the terminal where you ran `npx hardhat node`
  const VAULT_ADDR = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"; 
  
  const vault = await ethers.getContractAt("Vault", VAULT_ADDR);

  console.log(`watching vault at ${VAULT_ADDR}...`);

  // 2. THE LOOP
  // Poll for harvest opportunities every 10 seconds
  setInterval(async () => {
    try {
      console.log("🔍 Scanning for yield opportunities...");
      
      // In a real production agent, we would check: 
      // if (await strategy.estimatedHarvest() > gasCost) { ... }
      
      // For this Local Demo, we just FORCE a harvest to prove the UI updates
      const tx = await vault.harvest();
      await tx.wait();
      
      console.log("💰 Harvest Successful! Yield has been compounded.");
      console.log("   (Check your frontend: Bonded Balance should slightly increase)");
      
    } catch (e: any) {
      console.log("zzz No yield to harvest yet (or transaction failed).");
      // console.log(e.message); // Uncomment to see full error
    }
  }, 10000); // 10 seconds
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});