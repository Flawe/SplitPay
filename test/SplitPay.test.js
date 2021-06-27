// test/SplitPay.test.js

const { expect } = require('chai');
const { waffle } = require("hardhat");
const provider = waffle.provider;

describe('SplitPay', function() {
  before(async function() {
    this.accounts = await ethers.getSigners();
    this.SplitPay = await ethers.getContractFactory("SplitPay", this.accounts[0].address);
  });

  beforeEach(async function() {
    this.splitPay = await this.SplitPay.deploy();
    await this.splitPay.deployed();
  });

  it('Can not deposit 0 eth', async function() {
    const wallet0 = this.accounts[1];
    await expect(this.splitPay.deposit(wallet0.address, 98))
      .to.be.revertedWith("Can not deposit 0 wei");
  });

  it('Can not deposit with large percentage', async function() {
    const wallet0 = this.accounts[1];
    await expect(this.splitPay.deposit(wallet0.address, 101))
      .to.be.revertedWith("Percentage is higher than 100");
  });

  it('Can emit deposit event', async function() {
    const wallet0 = this.accounts[1];
    const override = { value: 100 };
    await expect(await this.splitPay.deposit(wallet0.address, 98, override))
      .to.emit(this.splitPay, "Deposit")
      .withArgs(wallet0.address, 100, 98);
  });

  it('Can deposit to contract', async function() {
    const wallet0 = this.accounts[1];
    const override = { value: 100 };
    await expect(await this.splitPay.deposit(wallet0.address, 98, override))
      .to.changeEtherBalance(this.splitPay, 100);
  });

  it('Can deposit to receiver', async function() {
    const wallet0 = this.accounts[1];
    const override = { value: 100 };
    await this.splitPay.deposit(wallet0.address, 98, override);
    await expect(await this.splitPay.depositsOf(wallet0.address))
      .to.equal(98);
  });

  it('Can deposit to owner', async function() {
    const owner = this.accounts[0];
    const wallet0 = this.accounts[1];
    const override = { value: 100 };
    await this.splitPay.deposit(wallet0.address, 98, override);
    await expect(await this.splitPay.depositsOf(owner.address))
      .to.equal(2);
  });

  it('Can not deposit 0 eth with referral', async function() {
    const wallet0 = this.accounts[1];
    const wallet1 = this.accounts[2];
    await expect(this.splitPay.depositReferral(wallet0.address, 98, wallet1.address, 1))
      .to.be.revertedWith("Can not split deposit 0 wei");
  });

  it('Can not deposit with referral and large percentage 1', async function() {
    const wallet0 = this.accounts[1];
    const wallet1 = this.accounts[2];
    const override = { value: 100 };
    await expect(this.splitPay.depositReferral(wallet0.address, 100, wallet1.address, 1, override))
      .to.be.revertedWith("Percentages add up to more than 100");
  });

  it('Can not deposit with referral and large percentage 2', async function() {
    const wallet0 = this.accounts[1];
    const wallet1 = this.accounts[2];
    const override = { value: 100 };
    await expect(this.splitPay.depositReferral(wallet0.address, 98, wallet1.address, 3, override))
      .to.be.revertedWith("Percentages add up to more than 100");
  });

  it('Can not deposit with referral and large percentage 3', async function() {
    const wallet0 = this.accounts[1];
    const wallet1 = this.accounts[2];
    const override = { value: 100 };
    await expect(this.splitPay.depositReferral(wallet0.address, 101, wallet1.address, 101, override))
      .to.be.revertedWith("Percentages add up to more than 100");
  });

  it('Can emit deposit with referral event', async function() {
    const wallet0 = this.accounts[1];
    const wallet1 = this.accounts[2];
    const override = { value: 100 };
    await expect(await this.splitPay.depositReferral(wallet0.address, 98, wallet1.address, 1, override))
      .to.emit(this.splitPay, "DepositReferral")
      .withArgs(wallet0.address, wallet1.address, 100, 98, 1);
  });

  it('Can deposit to contract with referral', async function() {
    const wallet0 = this.accounts[1];
    const wallet1 = this.accounts[2];
    const override = { value: 100 };
    await expect(await this.splitPay.depositReferral(wallet0.address, 98, wallet1.address, 1, override))
      .to.changeEtherBalance(this.splitPay, 100);
  });

  it('Can deposit to receiver with referral', async function() {
    const wallet0 = this.accounts[1];
    const wallet1 = this.accounts[2];
    const override = { value: 100 };
    await this.splitPay.depositReferral(wallet0.address, 98, wallet1.address, 1, override);
    await expect(await this.splitPay.depositsOf(wallet0.address))
      .to.equal(98);
  });

  it('Can deposit to referral', async function() {
    const wallet0 = this.accounts[1];
    const wallet1 = this.accounts[2];
    const override = { value: 100 };
    await this.splitPay.depositReferral(wallet0.address, 98, wallet1.address, 1, override);
    await expect(await this.splitPay.depositsOf(wallet1.address))
      .to.equal(1);
  });

  it('Can deposit to owner with referral', async function() {
    const owner = this.accounts[0];
    const wallet0 = this.accounts[1];
    const wallet1 = this.accounts[2];
    const override = { value: 100 };
    await this.splitPay.depositReferral(wallet0.address, 98, wallet1.address, 1, override);
    await expect(await this.splitPay.depositsOf(owner.address))
      .to.equal(1);
  });

  it('Can withdraw receiver funds after deposit', async function() {
    const wallet0 = this.accounts[1];
    const override = { value: 100 };
    await this.splitPay.deposit(wallet0.address, 98, override)
    await expect(await this.splitPay.connect(wallet0).withdraw())
      .to.changeEtherBalance(wallet0, 98);
  });

  it('Can withdraw owner funds after deposit', async function() {
    const owner = this.accounts[0];
    const wallet0 = this.accounts[1];
    const override = { value: 100 };
    await this.splitPay.deposit(wallet0.address, 98, override)
    await expect(await this.splitPay.withdraw())
      .to.changeEtherBalance(owner, 2);
  });

  it('Can decrement contract balance after withdraw', async function() {
    const wallet0 = this.accounts[1];
    const override = { value: 100 };
    await this.splitPay.deposit(wallet0.address, 98, override)
    await expect(await this.splitPay.connect(wallet0).withdraw())
      .to.changeEtherBalance(this.splitPay, -98);
  });

  it('Can withdraw receiver funds after deposit with referral', async function() {
    const wallet0 = this.accounts[1];
    const wallet1 = this.accounts[2];
    const override = { value: 100 };
    await this.splitPay.depositReferral(wallet0.address, 98, wallet1.address, 1, override);
    await expect(await this.splitPay.connect(wallet0).withdraw())
      .to.changeEtherBalance(wallet0, 98);
  });

  it('Can withdraw referral funds after deposit with referral', async function() {
    const wallet0 = this.accounts[1];
    const wallet1 = this.accounts[2];
    const override = { value: 100 };
    await this.splitPay.depositReferral(wallet0.address, 98, wallet1.address, 1, override);
    await expect(await this.splitPay.connect(wallet1).withdraw())
      .to.changeEtherBalance(wallet1, 1);
  });

  it('Can withdraw owner funds after deposit with referral', async function() {
    const owner = this.accounts[0];
    const wallet0 = this.accounts[1];
    const wallet1 = this.accounts[2];
    const override = { value: 100 };
    await this.splitPay.depositReferral(wallet0.address, 98, wallet1.address, 1, override);
    await expect(await this.splitPay.withdraw())
      .to.changeEtherBalance(owner, 1);
  });

  it('Can emit withdraw event', async function() {
    const wallet0 = this.accounts[1];
    const override = { value: 100 };
    await this.splitPay.deposit(wallet0.address, 98, override)
    await expect(await this.splitPay.connect(wallet0).withdraw())
      .to.emit(this.splitPay, "Withdraw")
      .withArgs(wallet0.address, 98);
  });
  
  it('Can reset deposited amount after withdraw', async function() {
    const wallet0 = this.accounts[1];
    const override = { value: 100 };
    await this.splitPay.deposit(wallet0.address, 98, override)
    await this.splitPay.connect(wallet0).withdraw();
    await expect(await this.splitPay.depositsOf(wallet0.address))
      .to.equal(0);
  });
});
