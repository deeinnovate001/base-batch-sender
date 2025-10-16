const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BatchSender", function () {
  let batchSender;
  let owner, user1, user2, user3;
  const FEE_WALLET = "0x75F387d2351785174f20474308C71E578feFCFF6";

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();
    
    const BatchSender = await ethers.getContractFactory("BatchSender");
    batchSender = await BatchSender.deploy();
    await batchSender.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await batchSender.owner()).to.equal(owner.address);
    });

    it("Should set the correct fee wallet", async function () {
      expect(await batchSender.FEE_WALLET()).to.equal(FEE_WALLET);
    });

    it("Should set initial fee to 0.1%", async function () {
      expect(await batchSender.feePercentage()).to.equal(10);
    });
  });

  describe("ETH Transfers", function () {
    it("Should send ETH to multiple addresses and charge fee", async function () {
      const recipients = [user1.address, user2.address];
      const amounts = [
        ethers.parseEther("0.01"),
        ethers.parseEther("0.02")
      ];
      
      const totalAmount = amounts.reduce((a, b) => a + b, BigInt(0));
      const fee = totalAmount / BigInt(1000); // 0.1%
      const totalRequired = totalAmount + fee;
      
      // Get initial balances
      const initialFeeWalletBalance = await ethers.provider.getBalance(FEE_WALLET);
      const initialUser1Balance = await ethers.provider.getBalance(user1.address);
      const initialUser2Balance = await ethers.provider.getBalance(user2.address);
      
      // Send transaction
      const tx = await batchSender.connect(user1).sendETH(recipients, amounts, {
        value: totalRequired
      });
      
      // Check final balances
      expect(await ethers.provider.getBalance(user1.address)).to.equal(
        initialUser1Balance - totalRequired + amounts[0]
      );
      
      expect(await ethers.provider.getBalance(user2.address)).to.equal(
        initialUser2Balance + amounts[1]
      );
    });

    it("Should reject if arrays length mismatch", async function () {
      const recipients = [user1.address, user2.address];
      const amounts = [ethers.parseEther("0.01")]; // Only one amount
      
      await expect(
        batchSender.sendETH(recipients, amounts, {
          value: ethers.parseEther("0.01")
        })
      ).to.be.revertedWith("Arrays must be same length");
    });
  });

  describe("Fee Management", function () {
    it("Should allow owner to set fee", async function () {
      await batchSender.setFeePercentage(5); // 0.05% fee
      expect(await batchSender.feePercentage()).to.equal(5);
    });

    it("Should reject non-owner from setting fee", async function () {
      await expect(
        batchSender.connect(user1).setFeePercentage(5)
      ).to.be.reverted;
    });
  });
});
