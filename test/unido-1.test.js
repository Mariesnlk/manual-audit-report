const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

let owner, user1;
let unidoDistribution;

describe("unido-1", function () {
    beforeEach(async () => {
        [owner, user1] = await ethers.getSigners();
        const UnidoDistribution = await ethers.getContractFactory(
            "UnidoDistribution"
        );

        unidoDistribution = await UnidoDistribution.deploy();

    });

    describe(" --- ", async () => {
        it("check name and symbol", async () => {
            console.log(await unidoDistribution.name());
        });
    });

    describe("addParticipants", async () => {
        it("addParticipants check enum", async () => {
            await unidoDistribution.addParticipants(2, [], []);
        });
    });


});
