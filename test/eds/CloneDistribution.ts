import { ethers } from 'hardhat';
import { Signer } from 'ethers';
import { expect } from 'chai';

describe('CloneDistribution', function () {
  let cloneDistribution: any;
  let owner: Signer;
  let addr1: Signer;
  let addr2: Signer;

  beforeEach(async function () {
    const CloneDistribution = await ethers.getContractFactory('MockCloneDistribution');
    [owner, addr1, addr2] = await ethers.getSigners();
    cloneDistribution = await CloneDistribution.deploy();
    await cloneDistribution.deployed();
  });

  it('should emit Distributed event', async function () {
    expect(await cloneDistribution.instantiate()).to.emit(cloneDistribution, 'Distributed');
  });

  it('Should read metadata', async function () {
    const metadata = await cloneDistribution.getMetadata();
    expect(metadata).to.equal('MockCloneDistribution');
  });
});
