import { ethers } from 'hardhat';
import { Signer } from 'ethers';
import { expect } from 'chai';
import { LaunchpadFactory } from '../typechain-types';

describe('LaunchpadFactory', () => {
  let owner: Signer;
  let launchpadFactory: LaunchpadFactory;
  let ownerAddress: string;

  beforeEach(async () => {
    // Deploy the LaunchpadFactory contract before each test
    [owner] = await ethers.getSigners();
    ownerAddress = await owner.getAddress();
    const LaunchpadFactory = await ethers.getContractFactory(
      'LaunchpadFactory'
    );
    launchpadFactory = await LaunchpadFactory.deploy();
  });

  it('Should deploy LaunchpadFactory and create a Launchpad contract', async () => {
    // Deploy a Launchpad contract using the factory
    const totalAmount = 10000;
    const saleStart = Math.floor(Date.now() / 1000) + 60; // One minute from now
    const saleEnd = saleStart + 3600; // One hour after saleStart
    const vestingStart = saleEnd + 60; // One minute after saleEnd
    const vestingEnd = vestingStart + 3600; // One hour after vestingStart
    const ratio = 100;

    await expect(
      launchpadFactory.createLaunchpad(
        ownerAddress,
        ownerAddress,
        totalAmount,
        saleStart,
        saleEnd,
        vestingStart,
        vestingEnd,
        ratio
      )
    )
      .to.emit(launchpadFactory, 'LaunchpadCreated')
      .withArgs(ownerAddress, ethers.ZeroAddress, ownerAddress);
  });

  it('Should require a 0.01 ETH fee for creating a Launchpad', async () => {
    // Attempt to create a Launchpad without paying the fee
    await expect(
      launchpadFactory.createLaunchpad(
        ownerAddress,
        ownerAddress,
        10000,
        1,
        2,
        3,
        4,
        100
      )
    ).to.be.revertedWith('0.01 ETH fee is required');
  });

  it('Should allow the owner to withdraw fees', async () => {
    // Send ETH to the contract
    await owner.sendTransaction({
      to: launchpadFactory.getAddress(),
      value: ethers.parseEther('0.01')
    });

    // Check the initial contract balance
    const initialBalance = await ethers.provider.getBalance(owner.getAddress());

    // Withdraw fees
    await launchpadFactory.connect(owner).withdraw();

    // Check the final contract balance
    const finalBalance = await ethers.provider.getBalance(owner.getAddress());

    // The final balance should be greater than the initial balance
    expect(finalBalance).to.be.gt(initialBalance);
  });
});
