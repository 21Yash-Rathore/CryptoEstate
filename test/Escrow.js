// * imports the `expect` funtion from the Chai library.
// * chai is a popular assertion library used for testing in javascript.*/
// * imports the `ethers` object from the Hardhat library.
// * Hardhat is a development environment for Ethereum smart contracts,
// * and ethers is a library that provides utilities for interacting with Ethereum.*/
const { expect } = require('chai');
const { ethers } = require('hardhat');

//* This function takes a number `n` as input, converts it to a string, and then uses
//* the `ethers.utils.parseUnits` method to convert the number to a representation of
//* tokens in the unit of 'ether'.This function is useful for converting numbers to token
// amounts in Ethereum.*/

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), 'ether');
};

describe('Escrow', () => {
  let seller, buyer, inspector, lender;
  let realEstate, escrow;

  beforeEach(async () => {
    //? setup Accounts
    [buyer, seller, inspector, lender] = await ethers.getSigners();

    //? Deploy Real Estate
    const RealEstate = await ethers.getContractFactory('RealEstate');
    realEstate = await RealEstate.deploy();

    //? Mint
    let transaction = await realEstate
      .connect(seller)
      .mint(
        'https://ipfs.io/ipfs/QmTudSYeM7mz3PkYEWXWqPjomRPHogcMFSq7XAvsvsgAPS',
      );
    await transaction.wait();

    //? Deploy Escrow
    const Escrow = await ethers.getContractFactory('Escrow');
    escrow = await Escrow.deploy(
      realEstate.address,
      seller.address,
      inspector.address,
      lender.address,
    );

    //? Approve property
    transaction = await realEstate.connect(seller).approve(escrow.address, 1);
    await transaction.wait();

    //? list property
    transaction = await escrow
      .connect(seller)
      .list(1, buyer.address, tokens(10), tokens(5));
    await transaction.wait();
  });

  describe('Deployment', () => {
    it('Return NFT address', async () => {
      const result = await escrow.nftAddress();
      expect(result).to.be.equal(realEstate.address);
    });

    it('Return seller', async () => {
      const result = await escrow.seller();
      expect(result).to.be.equal(seller.address);
    });

    it('Return lender', async () => {
      const result = await escrow.lender();
      expect(result).to.be.equal(lender.address);
    });

    it('Return inspector', async () => {
      const result = await escrow.inspector();
      expect(result).to.be.equal(inspector.address);
    });
  });

  describe('Listing', () => {
    it('Updates as listed', async () => {
      const result = await escrow.isListed(1);
      expect(result).to.be.equal(true);
    });

    it('Update ownership', async () => {
      expect(await realEstate.ownerOf(1)).to.be.equal(escrow.address);
    });

    it('Returns buyer', async () => {
      const result = await escrow.buyer(1);
      expect(result).to.be.equal(buyer.address);
    });

    it('Return purchase price', async () => {
      const result = await escrow.purchasePrice(1);
      expect(result).to.be.equal(tokens(10));
    });

    it('Returns escrow amount', async () => {
      const result = await escrow.escrowAmount(1);
      expect(result).to.be.equal(tokens(5));
    });
  });

  describe('Deposits', () => {
    it('Update contract balance', async () => {
      const transaction = await escrow
        .connect(buyer)
        .depositEarnest(1, { value: tokens(5) });
      await transaction.wait();
      const result = await escrow.getBalance();
      expect(result).to.be.equal(tokens(5));
    });
  });

  describe('Inspection', () => {
    beforeEach(async () => {
      const transaction = await escrow
        .connect(inspector)
        .updateInspectionStatus(1, true);
      await transaction.wait();
    });

    it('Updates inspection status', async () => {
      const result = await escrow.inspectionPassed(1);
      expect(result).to.be.equal(true);
    });
  });

  describe('Approval', () => {
    beforeEach(async () => {
      let transaction = await escrow.connect(buyer).approveSale(1);
      await transaction.wait();

      transaction = await escrow.connect(seller).approveSale(1);
      await transaction.wait();

      transaction = await escrow.connect(lender).approveSale(1);
      await transaction.wait();
    });

    it('Updates approval status', async () => {
      expect(await escrow.approval(1, buyer.address)).to.be.equal(true);
      expect(await escrow.approval(1, seller.address)).to.be.equal(true);
      expect(await escrow.approval(1, lender.address)).to.be.equal(true);
    });
  });

  describe('Sale', async () => {
    beforeEach(async () => {
      let transaction = await escrow
        .connect(buyer)
        .depositEarnest(1, { value: tokens(5) });
      await transaction.wait();

      transaction = await escrow
        .connect(inspector)
        .updateInspectionStatus(1, true);
      await transaction.wait();

      transaction = await escrow.connect(buyer).approveSale(1);
      await transaction.wait();

      transaction = await escrow.connect(seller).approveSale(1);
      await transaction.wait();

      transaction = await escrow.connect(lender).approveSale(1);
      await transaction.wait();

      await lender.sendTransaction({ to: escrow.address, value: tokens(5) });

      transaction = await escrow.connect(seller).finalizeSale(1);
      await transaction.wait();
    });

    it('Updates ownerShip', async () => {
      expect(await realEstate.ownerOf(1)).to.be.equal(buyer.address);
    });

    it('updates balance', async () => {
      expect(await escrow.getBalance()).to.be.equal(0);
    });
  });
});
