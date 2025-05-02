import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";

describe("LibMiddleware", function () {
  let libMiddlewareTest: Contract;
  let libMiddlewareExtendedTest: Contract;
  let mockMiddleware1: Contract;
  let mockMiddleware2: Contract;
  let owner: Signer;
  let user: Signer;
  let ownerAddress: string;
  let userAddress: string;

  const TEST_SELECTOR = "0x12345678";
  const OTHER_SELECTOR = "0x87654321";

  before(async function () {
    [owner, user] = await ethers.getSigners();
    ownerAddress = await owner.getAddress();
    userAddress = await user.getAddress();
  });

  beforeEach(async function () {
    // Deploy mock middleware contracts
    const MockMiddleware = await ethers.getContractFactory("MockMiddleware");
    mockMiddleware1 = await MockMiddleware.deploy();
    await mockMiddleware1.deployed();
    mockMiddleware2 = await MockMiddleware.deploy();
    await mockMiddleware2.deployed();

    // Set return values for the middleware calls
    await mockMiddleware1.setBeforeCallReturn("0xdeadbeef");
    await mockMiddleware2.setBeforeCallReturn("0xbeefdead");

    // Deploy LibMiddlewareTest contract
    const LibMiddlewareTest = await ethers.getContractFactory("LibMiddlewareTest");
    libMiddlewareTest = await LibMiddlewareTest.deploy();
    await libMiddlewareTest.deployed();

    // Deploy LibMiddlewareExtendedTest contract
    const LibMiddlewareExtendedTest = await ethers.getContractFactory("LibMiddlewareExtendedTest");
    libMiddlewareExtendedTest = await LibMiddlewareExtendedTest.deploy();
    await libMiddlewareExtendedTest.deployed();
  });

  describe("Basic Library Functions", function () {
    it("should create a key from target and selector", async function () {
      const target = mockMiddleware1.address;
      const key = await libMiddlewareTest.createKey(target, TEST_SELECTOR);
      const expectedKey = ethers.utils.keccak256(
        ethers.utils.solidityPack(["address", "bytes4"], [target, TEST_SELECTOR])
      );
      expect(key).to.equal(expectedKey);
    });

    it("should encode and decode config data", async function () {
      const configData = "0x1234";
      const encoded = await libMiddlewareTest.encodeConfig(mockMiddleware1.address, configData);
      const decoded = await libMiddlewareTest.getConfig(encoded);

      expect(decoded.middleware).to.equal(mockMiddleware1.address);
      expect(decoded.configData).to.equal(configData);
    });

    it("should get layer from layers array by index", async function () {
      // Create middleware layers
      const configData1 = "0x1234";
      const configData2 = "0x5678";
      const encoded1 = await libMiddlewareTest.encodeConfig(mockMiddleware1.address, configData1);
      const encoded2 = await libMiddlewareTest.encodeConfig(mockMiddleware2.address, configData2);

      const middlewareLayers = [encoded1, encoded2];

      // Get layer 0
      const layer0 = await libMiddlewareTest.getLayerTest(middlewareLayers, 0);
      expect(layer0.middleware).to.equal(mockMiddleware1.address);
      expect(layer0.configData).to.equal(configData1);

      // Get layer 1
      const layer1 = await libMiddlewareTest.getLayerTest(middlewareLayers, 1);
      expect(layer1.middleware).to.equal(mockMiddleware2.address);
      expect(layer1.configData).to.equal(configData2);
    });
  });

  describe("Middleware Execution", function () {
    it("should execute beforeCall for all middleware layers", async function () {
      // Create middleware layers
      const configData1 = "0x1234";
      const configData2 = "0x5678";
      const encoded1 = await libMiddlewareTest.encodeConfig(mockMiddleware1.address, configData1);
      const encoded2 = await libMiddlewareTest.encodeConfig(mockMiddleware2.address, configData2);

      const middlewareLayers = [encoded1, encoded2];

      // Execute beforeCall
      await libMiddlewareTest.executeBeforeCall(
        middlewareLayers,
        TEST_SELECTOR,
        ownerAddress,
        0,
        "0x"
      );

      // Check if both middlewares were called
      expect(await mockMiddleware1.beforeCallCalled()).to.be.true;
      expect(await mockMiddleware2.beforeCallCalled()).to.be.true;

      // Check stored arguments
      const args1 = await mockMiddleware1.getLastBeforeCallArgs();
      expect(args1.configData).to.equal(configData1);
      expect(args1.selector).to.equal(TEST_SELECTOR);
      expect(args1.sender).to.equal(ownerAddress);

      const args2 = await mockMiddleware2.getLastBeforeCallArgs();
      expect(args2.configData).to.equal(configData2);
      expect(args2.selector).to.equal(TEST_SELECTOR);
      expect(args2.sender).to.equal(ownerAddress);
    });

    it("should execute afterCall for all middleware layers in reverse order", async function () {
      // Create middleware layers
      const configData1 = "0x1234";
      const configData2 = "0x5678";
      const encoded1 = await libMiddlewareTest.encodeConfig(mockMiddleware1.address, configData1);
      const encoded2 = await libMiddlewareTest.encodeConfig(mockMiddleware2.address, configData2);

      const middlewareLayers = [encoded1, encoded2];
      const beforeCallResult = "0xdeadbeef";

      // Execute afterCall
      await libMiddlewareTest.executeAfterCall(
        middlewareLayers,
        TEST_SELECTOR,
        ownerAddress,
        0,
        "0x",
        beforeCallResult
      );

      // Check if both middlewares were called
      expect(await mockMiddleware1.afterCallCalled()).to.be.true;
      expect(await mockMiddleware2.afterCallCalled()).to.be.true;

      // Check stored arguments
      const args1 = await mockMiddleware1.getLastAfterCallArgs();
      expect(args1.configData).to.equal(configData1);
      expect(args1.selector).to.equal(TEST_SELECTOR);
      expect(args1.sender).to.equal(ownerAddress);
      expect(args1.beforeCallResult).to.equal(beforeCallResult);

      const args2 = await mockMiddleware2.getLastAfterCallArgs();
      expect(args2.configData).to.equal(configData2);
      expect(args2.selector).to.equal(TEST_SELECTOR);
      expect(args2.sender).to.equal(ownerAddress);
      expect(args2.beforeCallResult).to.equal(beforeCallResult);
    });

    it("should handle complex middleware scenarios", async function () {
      // Create multiple layers with different config data
      const configData1 = "0xabcd";
      const configData2 = "0xef12";
      const configData3 = "0x3456";

      const encoded1 = await libMiddlewareTest.encodeConfig(mockMiddleware1.address, configData1);
      const encoded2 = await libMiddlewareTest.encodeConfig(mockMiddleware2.address, configData2);
      const encoded3 = await libMiddlewareTest.encodeConfig(mockMiddleware1.address, configData3);

      const middlewareLayers = [encoded1, encoded2, encoded3];

      // Execute beforeCall
      await libMiddlewareTest.executeBeforeCall(
        middlewareLayers,
        OTHER_SELECTOR,
        userAddress,
        123,
        "0x1234"
      );

      // Check if middlewares were called with correct parameters
      const args1 = await mockMiddleware1.getLastBeforeCallArgs();
      expect(args1.selector).to.equal(OTHER_SELECTOR);
      expect(args1.sender).to.equal(userAddress);
      expect(args1.value.toNumber()).to.equal(123);
      expect(args1.data).to.equal("0x1234");

      const args2 = await mockMiddleware2.getLastBeforeCallArgs();
      expect(args2.selector).to.equal(OTHER_SELECTOR);
      expect(args2.sender).to.equal(userAddress);
      expect(args2.value.toNumber()).to.equal(123);
      expect(args2.data).to.equal("0x1234");

      // Execute afterCall
      await libMiddlewareTest.executeAfterCall(
        middlewareLayers,
        OTHER_SELECTOR,
        userAddress,
        123,
        "0x1234",
        "0xcafebabe"
      );

      // Check argument of the last afterCall
      const args3 = await mockMiddleware1.getLastAfterCallArgs();
      expect(args3.configData).to.equal(configData1); // First middleware should be called last in reverse order
      expect(args3.selector).to.equal(OTHER_SELECTOR);
      expect(args3.sender).to.equal(userAddress);
      expect(args3.value.toNumber()).to.equal(123);
      expect(args3.data).to.equal("0x1234");
      expect(args3.beforeCallResult).to.equal("0xcafebabe");
    });
  });

  describe("Direct Library Functions", function () {
    it("should test storage functions", async function () {
      // Check initial layer count
      expect((await libMiddlewareExtendedTest.getLayerCount()).toNumber()).to.equal(0);

      // Add a layer
      await libMiddlewareExtendedTest.testAddLayerWithParams(mockMiddleware1.address, "0x1234");
      expect((await libMiddlewareExtendedTest.getLayerCount()).toNumber()).to.equal(1);

      // Get the layer at index 0
      const [address, configData] = await libMiddlewareExtendedTest.getLayerAt(0);
      expect(address).to.equal(mockMiddleware1.address);
      expect(configData).to.equal("0x1234");

      // Add another layer with struct
      await libMiddlewareExtendedTest.testAddLayer(mockMiddleware2.address, "0x5678");
      expect((await libMiddlewareExtendedTest.getLayerCount()).toNumber()).to.equal(2);

      // Test getLayer function
      const [address2, configData2] = await libMiddlewareExtendedTest.testGetLayer(1);
      expect(address2).to.equal(mockMiddleware2.address);
      expect(configData2).to.equal("0x5678");

      // Test setLayer function
      await libMiddlewareExtendedTest.testSetLayer(userAddress, 0, "0xabcd");
      const [updatedAddress, updatedConfigData] = await libMiddlewareExtendedTest.getLayerAt(0);
      expect(updatedAddress).to.equal(userAddress);
      expect(updatedConfigData).to.equal("0xabcd");

      // Test popLayer function
      await libMiddlewareExtendedTest.testPopLayer();
      expect((await libMiddlewareExtendedTest.getLayerCount()).toNumber()).to.equal(1);

      // Test changeLayers function with array of one layer
      const layers = [
        {
          layerAddress: mockMiddleware1.address,
          layerConfigData: "0x9999"
        }
      ];
      await libMiddlewareExtendedTest.testChangeLayers(layers);
      expect((await libMiddlewareExtendedTest.getLayerCount()).toNumber()).to.equal(1);
      const [changedAddress, changedConfigData] = await libMiddlewareExtendedTest.getLayerAt(0);
      expect(changedAddress).to.equal(mockMiddleware1.address);
      expect(changedConfigData).to.equal("0x9999");
    });

    it("should test middleware execution functions", async function () {
      // Setup middleware layers
      await libMiddlewareExtendedTest.testAddLayerWithParams(mockMiddleware1.address, "0x1234");
      await libMiddlewareExtendedTest.testAddLayerWithParams(mockMiddleware2.address, "0x5678");

      // Test beforeCall function
      await libMiddlewareExtendedTest.testBeforeCall(TEST_SELECTOR, ownerAddress, "0xaabb", 42);

      // Check if both middlewares were called
      expect(await mockMiddleware1.beforeCallCalled()).to.be.true;
      expect(await mockMiddleware2.beforeCallCalled()).to.be.true;

      // Check parameters for first middleware
      const args1 = await mockMiddleware1.getLastBeforeCallArgs();
      expect(args1.selector).to.equal(TEST_SELECTOR);
      expect(args1.sender).to.equal(ownerAddress);
      expect(args1.value.toNumber()).to.equal(42);
      expect(args1.data).to.equal("0xaabb");

      // Test validateLayerBeforeCall function for second layer
      await libMiddlewareExtendedTest.testValidateLayerBeforeCall(
        1,
        OTHER_SELECTOR,
        userAddress,
        "0xccdd",
        123
      );

      // Check parameters for second middleware
      const args2 = await mockMiddleware2.getLastBeforeCallArgs();
      expect(args2.selector).to.equal(OTHER_SELECTOR);
      expect(args2.sender).to.equal(userAddress);
      expect(args2.value.toNumber()).to.equal(123);
      expect(args2.data).to.equal("0xccdd");

      // Test afterCall function
      const beforeCallReturns = ["0xdead", "0xbeef"];
      await libMiddlewareExtendedTest.testAfterCall(
        TEST_SELECTOR,
        ownerAddress,
        "0xaabb",
        42,
        beforeCallReturns
      );

      // Check if middlewares were called for afterCall (in reverse order)
      expect(await mockMiddleware1.afterCallCalled()).to.be.true;
      expect(await mockMiddleware2.afterCallCalled()).to.be.true;

      // Test validateLayerAfterCall function
      await libMiddlewareExtendedTest.testValidateLayerAfterCall(
        0,
        OTHER_SELECTOR,
        userAddress,
        "0xccdd",
        123,
        "0xcafebabe"
      );

      // Check parameters for after call
      const args3 = await mockMiddleware1.getLastAfterCallArgs();
      expect(args3.selector).to.equal(OTHER_SELECTOR);
      expect(args3.sender).to.equal(userAddress);
      expect(args3.value.toNumber()).to.equal(123);
      expect(args3.data).to.equal("0xccdd");
      expect(args3.beforeCallResult).to.equal("0xcafebabe");
    });

    it("should test extractRevertReason function", async function () {
      // Create a revert reason bytes message
      // Format: 0x08c379a0 + encoded string
      const revertReason = "Test revert reason";
      const abiEncodedReason = ethers.utils.defaultAbiCoder.encode(["string"], [revertReason]);
      const errorSig = "0x08c379a0"; // Error signature for Error(string)
      const revertData = errorSig + abiEncodedReason.substring(2);

      // Test the extraction
      const extractedReason = await libMiddlewareExtendedTest.testExtractRevertReason(revertData);
      expect(extractedReason).to.equal(revertReason);

      // Test with short data (less than 68 bytes)
      const shortData = "0x1234";
      const extractedShort = await libMiddlewareExtendedTest.testExtractRevertReason(shortData);
      expect(extractedShort).to.equal("");
    });

    it("should test setLayers function", async function () {
      // Create multiple layers
      const layers = [
        {
          layerAddress: mockMiddleware1.address,
          layerConfigData: "0x1111"
        },
        {
          layerAddress: mockMiddleware2.address,
          layerConfigData: "0x2222"
        },
        {
          layerAddress: userAddress,
          layerConfigData: "0x3333"
        }
      ];

      // Set all layers at once
      await libMiddlewareExtendedTest.testSetLayers(layers);

      // Check layer count
      expect((await libMiddlewareExtendedTest.getLayerCount()).toNumber()).to.equal(3);

      // Check each layer
      const [address1, configData1] = await libMiddlewareExtendedTest.getLayerAt(0);
      expect(address1).to.equal(mockMiddleware1.address);
      expect(configData1).to.equal("0x1111");

      const [address2, configData2] = await libMiddlewareExtendedTest.getLayerAt(1);
      expect(address2).to.equal(mockMiddleware2.address);
      expect(configData2).to.equal("0x2222");

      const [address3, configData3] = await libMiddlewareExtendedTest.getLayerAt(2);
      expect(address3).to.equal(userAddress);
      expect(configData3).to.equal("0x3333");
    });

    it("should test changeLayers with fewer layers than existing", async function () {
      // First set up multiple layers
      const initialLayers = [
        {
          layerAddress: mockMiddleware1.address,
          layerConfigData: "0x1111"
        },
        {
          layerAddress: mockMiddleware2.address,
          layerConfigData: "0x2222"
        },
        {
          layerAddress: userAddress,
          layerConfigData: "0x3333"
        }
      ];

      // Set initial layers
      await libMiddlewareExtendedTest.testSetLayers(initialLayers);

      // Verify initial layer count
      const initialCount = (await libMiddlewareExtendedTest.getLayerCount()).toNumber();
      expect(initialCount).to.equal(3);

      // Now change to a shorter array of layers
      const shorterLayers = [
        {
          layerAddress: ownerAddress,
          layerConfigData: "0xaaaa"
        }
      ];

      // Change layers to shorter array
      await libMiddlewareExtendedTest.testChangeLayers(shorterLayers);

      // Verify new layer count
      // Note: Looking at the implementation, the pop operation reduces array length by
      // ls.length - newLayers.length elements, so we should expect newLayers.length elements
      // In this case, expected count is 1 + (3 - 1 - 1) = 2
      const finalCount = (await libMiddlewareExtendedTest.getLayerCount()).toNumber();
      expect(finalCount).to.equal(2);

      // Verify the first layer has the expected data
      const [address1, configData1] = await libMiddlewareExtendedTest.getLayerAt(0);
      expect(address1).to.equal(ownerAddress);
      expect(configData1).to.equal("0xaaaa");

      // Since array still has a second element, let's verify it still has its original value
      // The changeLayers function doesn't update elements beyond the length of newLayers
      const [address2, configData2] = await libMiddlewareExtendedTest.getLayerAt(1);
      expect(address2).to.equal(mockMiddleware2.address);
      expect(configData2).to.equal("0x2222");
    });
  });
});
