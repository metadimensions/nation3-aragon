const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NationDao", function () {
    let nationDao;
    let mockNFT;
    let owner, voter1, voter2;
    let defaultVotingDuration = 86400; // 24 hours in seconds

    beforeEach(async function () {
        // Deploy MockNFT
        const MockNFT = await ethers.getContractFactory("MockNFT");
        mockNFT = await MockNFT.deploy();
        await mockNFT.deployed();

        // Use the deployer's address as a placeholder DAO address
        [owner, voter1, voter2] = await ethers.getSigners();

        const NationDao = await ethers.getContractFactory("NationDao");
        nationDao = await NationDao.deploy(mockNFT.address, owner.address, defaultVotingDuration);
        await nationDao.deployed();

        await mockNFT.mint(voter1.address, 1);
        await mockNFT.mint(voter2.address, 2);
    });

    describe("Proposal Creation", function () {
        it("should allow creating a proposal", async function () {
            await nationDao.connect(owner).createProposal("Test Proposal");
        });
    });

    describe("Voting", function () {
        let proposalId;

        beforeEach(async function () {
            const tx = await nationDao.connect(owner).createProposal("Test Proposal");
            const receipt = await tx.wait();
            proposalId = receipt.events[0].args.proposalId;
        });

        it("should allow a valid NFT holder to vote", async function () {
            await nationDao.connect(voter1).castVote(proposalId, true);
        });
    });
});
