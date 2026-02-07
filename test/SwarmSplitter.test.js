const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SwarmSplitter", function () {
  let splitter, owner, agent1, agent2, agent3;

  beforeEach(async function () {
    [owner, agent1, agent2, agent3] = await ethers.getSigners();
    const SwarmSplitter = await ethers.getContractFactory("SwarmSplitter");
    splitter = await SwarmSplitter.deploy(
      [agent1.address, agent2.address, agent3.address],
      [50, 30, 20]
    );
  });

  it("should store correct shares", async function () {
    expect(await splitter.shares(agent1.address)).to.equal(50);
    expect(await splitter.shares(agent2.address)).to.equal(30);
    expect(await splitter.shares(agent3.address)).to.equal(20);
  });

  it("should split received ETH correctly", async function () {
    await owner.sendTransaction({
      to: await splitter.getAddress(),
      value: ethers.parseEther("1.0")
    });

    const bal1Before = await ethers.provider.getBalance(agent1.address);
    await splitter.distribute();
    const bal1After = await ethers.provider.getBalance(agent1.address);

    expect(bal1After - bal1Before).to.equal(ethers.parseEther("0.5"));
  });

  it("should reject mismatched arrays", async function () {
    const SwarmSplitter = await ethers.getContractFactory("SwarmSplitter");
    await expect(
      SwarmSplitter.deploy(
        [agent1.address, agent2.address],
        [50, 30, 20]
      )
    ).to.be.revertedWith("Length mismatch");
  });
});
