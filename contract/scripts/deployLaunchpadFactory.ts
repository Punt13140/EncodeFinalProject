import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import { LaunchpadFactory__factory } from "../typechain-types";
dotenv.config();

async function main() {
  // Configuring the provider
  const provider = new ethers.JsonRpcProvider(
    process.env.RPC_ENDPOINT_URL ?? ""
  );

  // Configuring the wallet
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY ?? "", provider);
  console.log(`Using address ${wallet.address}`);
  const balanceBN = await provider.getBalance(wallet.address);
  const balance = Number(ethers.formatUnits(balanceBN));
  console.log(`Wallet balance ${balance} ETH`);
  if (balance < 0.01) {
    throw new Error("Not enough ether");
  }

  // Deploy launchpad factory
  const LaunchpadFactoryFactory = new LaunchpadFactory__factory(wallet);
  const LaunchpadFactoryContract = await LaunchpadFactoryFactory.deploy();
  await LaunchpadFactoryContract.waitForDeployment();
  console.log(`Contract deployed to ${LaunchpadFactoryContract.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});