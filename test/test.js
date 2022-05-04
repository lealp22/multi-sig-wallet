const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiSigWallet", function () {
  it("Should return the new greeting once it's changed", async function () {

    let owners = ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"];
    let numConfirmationsRequired = 2;

    const MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
    const multiSigWallet = await MultiSigWallet.deploy(owners, numConfirmationsRequired);
    await multiSigWallet.deployed();

    expect(await multiSigWallet.greet()).to.equal("Hello, world!");

    const setGreetingTx = await multiSigWallet.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await multiSigWallet.greet()).to.equal("Hola, mundo!");
  });
});
