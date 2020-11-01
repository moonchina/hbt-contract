const { expectRevert, time, BN } = require('@openzeppelin/test-helpers');
const HBTLock = artifacts.require('HBTLock');
const MasterChef = artifacts.require('MasterChef');
const MockERC20 = artifacts.require('MockERC20');
const HBTToken = artifacts.require('HBTToken');
const PlayerBook = artifacts.require('PlayerBook');

contract('HBTLock', ([alice, bob, carol, dev, minter]) => {
    beforeEach(async () => {
        this.playerBook = await PlayerBook.new(dev,{ from: alice });
    });

    it('生成注册连接', async () => {


    });
});