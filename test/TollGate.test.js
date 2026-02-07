const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TollGate", function () {
  let tollGate, owner, service, caller;

  beforeEach(async function () {
    [owner, service, caller] = await ethers.getSigners();
    const TollGate = await ethers.getContractFactory("TollGate");
    tollGate = await TollGate.deploy();
  });

  it("should register a service with a price", async function () {
    await tollGate.connect(service).register(ethers.parseEther("0.01"));
    expect(await tollGate.toll(service.address)).to.equal(ethers.parseEther("0.01"));
  });

  it("should accept payment for a registered service", async function () {
    await tollGate.connect(service).register(ethers.parseEther("0.01"));
    await tollGate.connect(caller).payToll(service.address, {
      value: ethers.parseEther("0.01")
    });
    expect(await tollGate.earned(service.address)).to.equal(ethers.parseEther("0.01"));
  });

  it("should reject underpayment", async function () {
    await tollGate.connect(service).register(ethers.parseEther("0.01"));
    await expect(
      tollGate.connect(caller).payToll(service.address, {
        value: ethers.parseEther("0.001")
      })
    ).to.be.revertedWith("Insufficient payment");
  });

  it("should allow service to withdraw earnings", async function () {
    await tollGate.connect(service).register(ethers.parseEther("0.01"));
    await tollGate.connect(caller).payToll(service.address, {
      value: ethers.parseEther("0.01")
    });

    const balanceBefore = await ethers.provider.getBalance(service.address);
    const tx = await tollGate.connect(service).withdraw();
    const receipt = await tx.wait();
    const gasUsed = receipt.gasUsed * receipt.gasPrice;
    const balanceAfter = await ethers.provider.getBalance(service.address);

    expect(balanceAfter + gasUsed - balanceBefore).to.equal(ethers.parseEther("0.01"));
  });

  it("should reject withdrawal with zero balance", async function () {
    await expect(
      tollGate.connect(service).withdraw()
    ).to.be.revertedWith("Nothing to withdraw");
  });
});
