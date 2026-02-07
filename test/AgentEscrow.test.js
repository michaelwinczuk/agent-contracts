const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("AgentEscrow", function () {
  let escrow, buyer, provider;
  const taskHash = ethers.keccak256(ethers.toUtf8Bytes("generate-nft-art"));

  beforeEach(async function () {
    [buyer, provider] = await ethers.getSigners();
    const AgentEscrow = await ethers.getContractFactory("AgentEscrow");
    escrow = await AgentEscrow.deploy();
  });

  it("should create a deal with funds locked", async function () {
    const tx = await escrow.connect(buyer).createDeal(
      provider.address,
      taskHash,
      3600,
      { value: ethers.parseEther("0.1") }
    );
    const receipt = await tx.wait();
    
    const deal = await escrow.deals(0);
    expect(deal.buyer).to.equal(buyer.address);
    expect(deal.provider).to.equal(provider.address);
    expect(deal.amount).to.equal(ethers.parseEther("0.1"));
  });

  it("should allow buyer to confirm delivery", async function () {
    await escrow.connect(buyer).createDeal(
      provider.address,
      taskHash,
      3600,
      { value: ethers.parseEther("0.1") }
    );

    const balanceBefore = await ethers.provider.getBalance(provider.address);
    await escrow.connect(buyer).confirmDelivery(0);
    const balanceAfter = await ethers.provider.getBalance(provider.address);

    expect(balanceAfter - balanceBefore).to.equal(ethers.parseEther("0.1"));
  });

  it("should reject confirmation from non-buyer", async function () {
    await escrow.connect(buyer).createDeal(
      provider.address,
      taskHash,
      3600,
      { value: ethers.parseEther("0.1") }
    );

    await expect(
      escrow.connect(provider).confirmDelivery(0)
    ).to.be.revertedWith("Only buyer");
  });

  it("should allow refund after deadline", async function () {
    await escrow.connect(buyer).createDeal(
      provider.address,
      taskHash,
      3600,
      { value: ethers.parseEther("0.1") }
    );

    await time.increase(3601);

    const balanceBefore = await ethers.provider.getBalance(buyer.address);
    const tx = await escrow.connect(buyer).disputeDeal(0);
    const receipt = await tx.wait();
    const gasUsed = receipt.gasUsed * receipt.gasPrice;
    const balanceAfter = await ethers.provider.getBalance(buyer.address);

    expect(balanceAfter + gasUsed - balanceBefore).to.equal(ethers.parseEther("0.1"));
  });
});
