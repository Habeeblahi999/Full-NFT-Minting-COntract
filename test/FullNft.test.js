const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FullNFT", function () {
  let contract;
  let owner;
  let account2;
  let account3;

  beforeEach(async function () {
    [owner, account2, account3] = await ethers.getSigners();

    const FullNFT = await ethers.getContractFactory("FullNFT");
    contract = await FullNFT.deploy(
      "MyNFT",
      "MNFT",
      "https://hidden.example.com/metadata.json",
      ethers.ZeroHash
    );
  });

  // ── Basic Info ──
  describe("Deployment", function () {
    it("Should set correct name and symbol", async function () {
      expect(await contract.name()).to.equal("MyNFT");
      expect(await contract.symbol()).to.equal("MNFT");
    });

    it("Should set correct max supply", async function () {
      expect(await contract.maxSupply()).to.equal(1000);
    });

    it("Should set correct mint price", async function () {
      expect(await contract.publicMintPrice()).to.equal(
        ethers.parseEther("0.01")
      );
    });
  });

  // ── Owner Mint ──
  describe("Owner Mint", function () {
    it("Should allow owner to mint for free", async function () {
      await contract.ownerMint(account2.address, 3);
      expect(await contract.totalMinted()).to.equal(3);
      expect(await contract.balanceOf(account2.address)).to.equal(3);
    });

    it("Should not allow non owner to mint for free", async function () {
      await expect(
        contract.connect(account2).ownerMint(account2.address, 3)
      ).to.be.reverted;
    });
  });

  // ── Public Mint ──
  describe("Public Mint", function () {
    beforeEach(async function () {
      await contract.setPublicSaleActive(true);
    });

    it("Should allow public mint with correct ETH", async function () {
      await contract.connect(account2).mint(2, {
        value: ethers.parseEther("0.02"),
      });
      expect(await contract.totalMinted()).to.equal(2);
      expect(await contract.balanceOf(account2.address)).to.equal(2);
    });

    it("Should fail if insufficient ETH sent", async function () {
      await expect(
        contract.connect(account2).mint(2, {
          value: ethers.parseEther("0.01"),
        })
      ).to.be.revertedWith("Insufficient ETH");
    });

    it("Should fail if public sale is not active", async function () {
      await contract.setPublicSaleActive(false);
      await expect(
        contract.connect(account2).mint(2, {
          value: ethers.parseEther("0.02"),
        })
      ).to.be.revertedWith("Public sale not active");
    });

    it("Should fail if max per wallet exceeded", async function () {
      await expect(
        contract.connect(account2).mint(4, {
          value: ethers.parseEther("0.04"),
        })
      ).to.be.revertedWith("Exceeds max per wallet");
    });
  });

  // ── Pause ──
  describe("Pause", function () {
    it("Should pause and prevent minting", async function () {
      await contract.setPublicSaleActive(true);
      await contract.pause();
      await expect(
        contract.connect(account2).mint(2, {
          value: ethers.parseEther("0.02"),
        })
      ).to.be.reverted;
    });

    it("Should unpause and allow minting", async function () {
      await contract.setPublicSaleActive(true);
      await contract.pause();
      await contract.unpause();
      await contract.connect(account2).mint(2, {
        value: ethers.parseEther("0.02"),
      });
      expect(await contract.totalMinted()).to.equal(2);
    });
  });

  // ── Reveal ──
  describe("Reveal", function () {
    it("Should return hidden metadata before reveal", async function () {
      await contract.ownerMint(account2.address, 1);
      expect(await contract.tokenURI(1)).to.equal(
        "https://hidden.example.com/metadata.json"
      );
    });

    it("Should return real metadata after reveal", async function () {
      await contract.ownerMint(account2.address, 1);
      await contract.reveal("https://mybaseuri.example.com/metadata");
      expect(await contract.tokenURI(1)).to.equal(
        "https://mybaseuri.example.com/metadata/1.json"
      );
    });
  });

  // ── Withdraw ──
  describe("Withdraw", function () {
    it("Should allow owner to withdraw funds", async function () {
      await contract.setPublicSaleActive(true);
      await contract.connect(account2).mint(2, {
        value: ethers.parseEther("0.02"),
      });
      const balanceBefore = await ethers.provider.getBalance(owner.address);
      await contract.withdraw();
      const balanceAfter = await ethers.provider.getBalance(owner.address);
      expect(balanceAfter).to.be.gt(balanceBefore);
    });

    it("Should fail if nothing to withdraw", async function () {
      await expect(contract.withdraw()).to.be.revertedWith(
        "Nothing to withdraw"
      );
    });
  });
});
