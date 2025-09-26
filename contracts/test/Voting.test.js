const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Voting", function () {
  let Voting, voting, owner, addr1, addr2;

  beforeEach(async function () {
    Voting = await ethers.getContractFactory("Voting");
    [owner, addr1, addr2] = await ethers.getSigners();
    voting = await Voting.deploy();
    await voting.waitForDeployment();
  });

  it("Should create a poll", async function () {
    await voting.createPoll("Test Poll", ["Option 1", "Option 2"]);
    const options = await voting.getOptions(0);
    expect(options).to.deep.equal(["Option 1", "Option 2"]);
  });

  it("Should allow voting", async function () {
    await voting.createPoll("Test Poll", ["Option 1", "Option 2"]);
    await voting.connect(addr1).vote(0, 0); // Vote for option 0
    const tallies = await voting.getTallies(0);
    expect(tallies[0]).to.equal(1);
    expect(tallies[1]).to.equal(0);
  });

  it("Should prevent double voting", async function () {
    await voting.createPoll("Test Poll", ["Option 1", "Option 2"]);
    await voting.connect(addr1).vote(0, 0);
    await expect(voting.connect(addr1).vote(0, 1)).to.be.revertedWith("Already voted");
  });

  it("Should close poll", async function () {
    await voting.createPoll("Test Poll", ["Option 1", "Option 2"]);
    await voting.closePoll(0);
    // After closing, voting should fail
    await expect(voting.connect(addr1).vote(0, 0)).to.be.revertedWith("Poll is closed");
  });

  it("Should emit VoteCast event", async function () {
    await voting.createPoll("Test Poll", ["Option 1", "Option 2"]);
    await expect(voting.connect(addr1).vote(0, 0))
      .to.emit(voting, "VoteCast")
      .withArgs(0, 0, addr1.address);
  });
});