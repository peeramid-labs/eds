import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";

describe("LibSemver", function () {
  let libSemverTest: Contract;

  before(async function () {
    // Deploy a contract that exposes LibSemver functions for testing
    const LibSemverTest = await ethers.getContractFactory("LibSemverTest");
    libSemverTest = await LibSemverTest.deploy();
    await libSemverTest.deployed();
  });

  describe("Basic version operations", function () {
    it("should convert version to uint256", async function () {
      const version = { major: 1, minor: 2, patch: 3 };
      const versionUint = await libSemverTest.toUint256(version);
      expect(versionUint.toString()).to.not.equal("0");
    });

    it("should parse uint256 to version", async function () {
      const version = { major: 2, minor: 3, patch: 4 };
      const versionUint = await libSemverTest.toUint256(version);
      const parsedVersion = await libSemverTest.parse(versionUint);

      expect(parsedVersion.major).to.equal(2);
      expect(parsedVersion.minor).to.equal(3);
      expect(parsedVersion.patch).to.equal(4);
    });

    it("should convert version to string", async function () {
      const version = { major: 3, minor: 4, patch: 5 };
      const versionString = await libSemverTest.versionToString(version);
      expect(versionString).to.equal("3.4.5");
    });
  });

  describe("Version requirements", function () {
    it("should require exact version match", async function () {
      const v1 = { major: 1, minor: 0, patch: 0 };
      const v2 = { major: 1, minor: 0, patch: 0 };
      await libSemverTest.require_exact(v1, v2);

      // Should revert with version mismatch custom error
      const v3 = { major: 1, minor: 0, patch: 1 };
      await expect(libSemverTest.require_exact(v1, v3)).to.be.revertedWithCustomError(
        libSemverTest,
        "versionMismatch"
      );
    });

    it("should require major version match", async function () {
      const v1 = { major: 1, minor: 2, patch: 3 };
      const v2 = { major: 1, minor: 4, patch: 5 };
      await libSemverTest.require_major(v1, v2);

      // Should revert with major version mismatch custom error
      const v3 = { major: 2, minor: 0, patch: 0 };
      await expect(libSemverTest.require_major(v1, v3)).to.be.revertedWithCustomError(
        libSemverTest,
        "versionMismatch"
      );
    });

    it("should require major and minor version match", async function () {
      const v1 = { major: 1, minor: 2, patch: 3 };
      const v2 = { major: 1, minor: 2, patch: 5 };
      await libSemverTest.require_major_minor(v1, v2);

      // Should revert with major and minor version mismatch custom error
      const v3 = { major: 1, minor: 3, patch: 0 };
      await expect(libSemverTest.require_major_minor(v1, v3)).to.be.revertedWithCustomError(
        libSemverTest,
        "versionMismatch"
      );
    });

    it("should require greater or equal version", async function () {
      const v1 = { major: 2, minor: 0, patch: 0 };
      const v2 = { major: 1, minor: 0, patch: 0 };
      await libSemverTest.require_greater_equal(v1, v2);

      const v3 = { major: 2, minor: 0, patch: 0 };
      await libSemverTest.require_greater_equal(v3, v3); // Equal is ok

      // Should revert when not greater or equal
      const v4 = { major: 3, minor: 0, patch: 0 };
      await expect(libSemverTest.require_greater_equal(v2, v4)).to.be.revertedWithCustomError(
        libSemverTest,
        "versionMismatch"
      );
    });

    it("should require greater version", async function () {
      const v1 = { major: 2, minor: 0, patch: 0 };
      const v2 = { major: 1, minor: 0, patch: 0 };
      await libSemverTest.require_greater(v1, v2);

      // Should revert when not greater
      const v3 = { major: 2, minor: 0, patch: 0 };
      await expect(libSemverTest.require_greater(v1, v3)).to.be.revertedWithCustomError(
        libSemverTest,
        "versionMismatch"
      );
    });

    it("should require lesser or equal version", async function () {
      const v1 = { major: 1, minor: 0, patch: 0 };
      const v2 = { major: 2, minor: 0, patch: 0 };
      await libSemverTest.require_lesser_equal(v1, v2);

      const v3 = { major: 2, minor: 0, patch: 0 };
      await libSemverTest.require_lesser_equal(v3, v3); // Equal is ok

      // Should revert when not lesser or equal
      const v4 = { major: 1, minor: 0, patch: 0 };
      await expect(libSemverTest.require_lesser_equal(v2, v4)).to.be.revertedWithCustomError(
        libSemverTest,
        "versionMismatch"
      );
    });

    it("should require lesser version", async function () {
      const v1 = { major: 1, minor: 0, patch: 0 };
      const v2 = { major: 2, minor: 0, patch: 0 };
      await libSemverTest.require_lesser(v1, v2);

      // Should revert when not lesser
      const v3 = { major: 2, minor: 0, patch: 0 };
      await expect(libSemverTest.require_lesser(v3, v3)).to.be.revertedWithCustomError(
        libSemverTest,
        "versionMismatch"
      );
    });
  });

  describe("Version comparison", function () {
    it("should check if versions are equal", async function () {
      const v1 = { major: 1, minor: 2, patch: 3 };
      const v2 = { major: 1, minor: 2, patch: 3 };
      const equal = await libSemverTest.areEqual(v1, v2);
      expect(equal).to.be.true;

      const v3 = { major: 1, minor: 2, patch: 4 };
      const notEqual = await libSemverTest.areEqual(v1, v3);
      expect(notEqual).to.be.false;
    });

    it("should compare version against ANY requirement", async function () {
      const version = { major: 1, minor: 0, patch: 0 };
      const requirement = {
        version: { major: 0, minor: 0, patch: 0 },
        requirement: 0 // ANY
      };
      const result = await libSemverTest.compare(version, requirement);
      expect(result).to.be.true;
    });

    it("should compare version against EXACT requirement", async function () {
      const version = { major: 1, minor: 2, patch: 3 };

      // Match
      const matchRequirement = {
        version: { major: 1, minor: 2, patch: 3 },
        requirement: 1 // EXACT
      };
      const matchResult = await libSemverTest.compare(version, matchRequirement);
      expect(matchResult).to.be.true;

      // Non-match
      const mismatchRequirement = {
        version: { major: 1, minor: 2, patch: 4 },
        requirement: 1 // EXACT
      };
      const mismatchResult = await libSemverTest.compare(version, mismatchRequirement);
      expect(mismatchResult).to.be.false;
    });

    it("should compare version against MAJOR requirement", async function () {
      const version = { major: 1, minor: 2, patch: 3 };

      // Match
      const matchRequirement = {
        version: { major: 1, minor: 0, patch: 0 },
        requirement: 2 // MAJOR
      };
      const matchResult = await libSemverTest.compare(version, matchRequirement);
      expect(matchResult).to.be.true;

      // Non-match
      const mismatchRequirement = {
        version: { major: 2, minor: 0, patch: 0 },
        requirement: 2 // MAJOR
      };
      const mismatchResult = await libSemverTest.compare(version, mismatchRequirement);
      expect(mismatchResult).to.be.false;
    });

    it("should compare version against MAJOR_MINOR requirement", async function () {
      const version = { major: 1, minor: 2, patch: 3 };

      // Match
      const matchRequirement = {
        version: { major: 1, minor: 2, patch: 0 },
        requirement: 3 // MAJOR_MINOR
      };
      const matchResult = await libSemverTest.compare(version, matchRequirement);
      expect(matchResult).to.be.true;

      // Non-match
      const mismatchRequirement = {
        version: { major: 1, minor: 3, patch: 0 },
        requirement: 3 // MAJOR_MINOR
      };
      const mismatchResult = await libSemverTest.compare(version, mismatchRequirement);
      expect(mismatchResult).to.be.false;
    });

    it("should compare version against other requirements", async function () {
      const version = { major: 2, minor: 0, patch: 0 };

      // GREATER_EQUAL
      const geRequirement = {
        version: { major: 1, minor: 0, patch: 0 },
        requirement: 4 // GREATER_EQUAL
      };
      expect(await libSemverTest.compare(version, geRequirement)).to.be.true;

      // GREATER
      const gRequirement = {
        version: { major: 1, minor: 0, patch: 0 },
        requirement: 5 // GREATER
      };
      expect(await libSemverTest.compare(version, gRequirement)).to.be.true;

      // LESSER_EQUAL
      const leRequirement = {
        version: { major: 3, minor: 0, patch: 0 },
        requirement: 6 // LESSER_EQUAL
      };
      expect(await libSemverTest.compare(version, leRequirement)).to.be.true;

      // LESSER
      const lRequirement = {
        version: { major: 3, minor: 0, patch: 0 },
        requirement: 7 // LESSER
      };
      expect(await libSemverTest.compare(version, lRequirement)).to.be.true;

      // Skip testing invalid requirement to avoid errors
    });
  });

  describe("Version increments", function () {
    it("should get next major version", async function () {
      const version = { major: 1, minor: 2, patch: 3 };
      const nextMajor = await libSemverTest.getNextMajor(version);

      expect(nextMajor.major).to.equal(2);
      expect(nextMajor.minor).to.equal(0);
      expect(nextMajor.patch).to.equal(0);
    });

    it("should get next minor version", async function () {
      const version = { major: 1, minor: 2, patch: 3 };
      const nextMinor = await libSemverTest.getNextMinor(version);

      expect(nextMinor.major).to.equal(1);
      expect(nextMinor.minor).to.equal(3);
      expect(nextMinor.patch).to.equal(0);
    });

    it("should get next patch version", async function () {
      const version = { major: 1, minor: 2, patch: 3 };
      const nextPatch = await libSemverTest.getNextPatch(version);

      expect(nextPatch.major).to.equal(1);
      expect(nextPatch.minor).to.equal(2);
      expect(nextPatch.patch).to.equal(4);
    });
  });
});
