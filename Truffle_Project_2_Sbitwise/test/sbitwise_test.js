const Sbitwise = artifacts.require("Sbitwise");
const truffleAssert = require('truffle-assertions');

contract("Sbitwise", accounts => {
    
    it("group admin should be accounts[0]", async () => {
        let instance = await Sbitwise.deployed();
        let owner = await instance.groupAdmin();
        assert.equal(owner, accounts[0]);
    });

    it("People who are added should be group members", async () => {
        let instance = await Sbitwise.deployed();
        await debug(instance.addToGroup(accounts[1], "Richard", {from: accounts[0]}));
        let memberAddress = await instance.memberAddresses(1);
        let memberStruct = await instance.groupMembers(memberAddress);
        assert.equal(memberAddress, accounts[1]);
        assert.equal(memberStruct.name, "Richard");
    });

    describe("Financial Calculations", () => {
        it("Calling add to paid should set value paid in groupmember struct", async () => {
            let instance = await Sbitwise.deployed();
            await instance.addToGroup(accounts[1], "Richard", {from: accounts[0]});
            await instance.agreeToSplit({from: accounts[0]});
            let member1Struct = await instance.groupMembers(accounts[0]);
            assert.equal(member1Struct.confirmedSplit, 1);
            await instance.addToPaid(15, {from: accounts[1]});
            member1Struct = await instance.groupMembers(accounts[0]);
            assert.equal(member1Struct.confirmedSplit, 0);
            let member2Struct = await instance.groupMembers(accounts[1]);
            assert.equal(member2Struct.amountPaid, 15);
            await instance.addToPaid(20, {from: accounts[1]});
            member2Struct = await instance.groupMembers(accounts[1]);
            assert.equal(member2Struct.amountPaid, 35);
        });

        it("Split Calculation should update correctly, users should be able to put money in the contract, send all money back should return funds", async () => {
            let instance = await Sbitwise.deployed();
            await instance.addToGroup(accounts[1], "Richard", {from: accounts[0]});
            await instance.addToGroup(accounts[2], "Jim", {from: accounts[0]});
            await instance.addToGroup(accounts[3], "Ted", {from: accounts[0]});
            await instance.addToGroup(accounts[4], "Max", {from: accounts[0]});
            await instance.addToPaid(10, {from: accounts[0]});
            await instance.addToPaid(15, {from: accounts[1]});
            await instance.addToPaid(35, {from: accounts[2]});
            await instance.agreeToSplit({from: accounts[0]});
            await instance.agreeToSplit({from: accounts[1]});
            await instance.agreeToSplit({from: accounts[2]});
            await instance.agreeToSplit({from: accounts[3]});
            await instance.agreeToSplit({from: accounts[4]});
            await instance.printSplit();
            await instance.putMoneyInContract({value: 2, from: accounts[0]});
            await instance.putMoneyInContract({value: 12, from: accounts[3]});
            let chrisBalance = await instance.balances(accounts[0]);
            let richardBalance = await instance.balances(accounts[1]);
            let tedBalance = await instance.balances(accounts[3]);
            let maxBalance = await instance.balances(accounts[4]);
            assert.equal(chrisBalance, 2);
            assert.equal(richardBalance, 0);
            assert.equal(tedBalance, 12);
            assert.equal(maxBalance, 0);
            //await instance.putMoneyInContract({value: 12, from: accounts[4]});
            await debug (instance.sendAllMoneyBack({from: accounts[0]}));
            chrisBalance = await instance.balances(accounts[0]);
            richardBalance = await instance.balances(accounts[1]);
            let jimBalance = await instance.balances(accounts[2]);
            tedBalance = await instance.balances(accounts[3]);
            maxBalance = await instance.balances(accounts[4]);
            assert.equal(chrisBalance, 0);
            assert.equal(richardBalance, 0);
            assert.equal(jimBalance, 0);
            assert.equal(tedBalance, 0);
            assert.equal(maxBalance, 0);
        });
    });

    describe("Group Member Management", () => {
        it("Should be able to remove a group member", async () => {
            let instance = await Sbitwise.deployed();
            await instance.addToGroup(accounts[1], "Richard", {from: accounts[0]});
            await instance.addToGroup(accounts[2], "Jim", {from: accounts[0]});
            await instance.removeFromGroup(accounts[1]);
            let memberAddress = await instance.memberAddresses(1);
            assert.equal(memberAddress, accounts[2]);
        });

        it("Change admin, new admin should be accounts[3]", async () => {
            let instance = await Sbitwise.deployed();
            await instance.addToGroup(accounts[1], "Richard", {from: accounts[0]});
            await instance.changeAdmin(accounts[1], {from: accounts[0]});
            let owner = await instance.groupAdmin();
            assert.equal(owner, accounts[1]);
        });
    });

    //TO TEST BEFORE DEPLOYMENT TO MAINNET: Does settleup() interact with accounts correctly
});
