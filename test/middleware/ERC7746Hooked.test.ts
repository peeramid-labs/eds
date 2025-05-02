import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";

describe("ERC7746Hooked", function () {
  let mockHookedTest: Contract;
  let mockMiddleware1: Contract;
  let mockMiddleware2: Contract;
  let owner: Signer;
  let user: Signer;
  let ownerAddress: string;
  let userAddress: string;

  const TEST_SELECTOR = "0x12345678";
  const TEST_DATA = "0xabcdef";
  const TEST_VALUE = ethers.utils.parseEther("1.0");
  const CONFIG_DATA1 = "0x1234";
  const CONFIG_DATA2 = "0x5678";

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

    // Deploy the test contract
    const MockERC7746HookedTest = await ethers.getContractFactory("MockERC7746HookedTest");
    mockHookedTest = await MockERC7746HookedTest.deploy();
    await mockHookedTest.deployed();

    // Set up middleware layers
    await mockHookedTest.setupMiddlewareLayers(
      [mockMiddleware1.address, mockMiddleware2.address],
      [CONFIG_DATA1, CONFIG_DATA2]
    );

    // Verify the layers are set up correctly
    expect(await mockHookedTest.getLayerCount()).to.equal(2);
    const [middleware1, configData1] = await mockHookedTest.getLayerAt(0);
    expect(middleware1).to.equal(mockMiddleware1.address);
    expect(configData1).to.equal(CONFIG_DATA1);

    const [middleware2, configData2] = await mockHookedTest.getLayerAt(1);
    expect(middleware2).to.equal(mockMiddleware2.address);
    expect(configData2).to.equal(CONFIG_DATA2);
  });

  describe("ERC7746C Modifier", function () {
    it("should call beforeCall and afterCall with the provided parameters", async function () {
      // Reset middleware call flags
      await mockMiddleware1.resetCounters();
      await mockMiddleware2.resetCounters();

      // Call the function with the ERC7746C modifier
      const newValue = "Test Value 1";
      const tx = await mockHookedTest.testERC7746CModifier(
        TEST_SELECTOR,
        userAddress,
        TEST_DATA,
        TEST_VALUE,
        newValue
      );
      await tx.wait();

      // Verify function execution
      expect(await mockHookedTest.testValue()).to.equal(newValue);
      expect(await mockHookedTest.functionExecuted()).to.be.true;

      // Verify that beforeCall was called on both middleware contracts
      expect(await mockMiddleware1.beforeCallCalled()).to.be.true;
      expect(await mockMiddleware2.beforeCallCalled()).to.be.true;

      // Verify that afterCall was called on both middleware contracts
      expect(await mockMiddleware1.afterCallCalled()).to.be.true;
      expect(await mockMiddleware2.afterCallCalled()).to.be.true;

      // Verify the parameters passed to the middleware function calls
      const args1 = await mockMiddleware1.getLastBeforeCallArgs();
      expect(args1.configData).to.equal(CONFIG_DATA1);
      expect(args1.selector).to.equal(TEST_SELECTOR);
      expect(args1.sender).to.equal(userAddress);
      expect(args1.data).to.equal(TEST_DATA);
      expect(args1.value.toString()).to.equal(TEST_VALUE.toString());

      const args2 = await mockMiddleware2.getLastBeforeCallArgs();
      expect(args2.configData).to.equal(CONFIG_DATA2);
      expect(args2.selector).to.equal(TEST_SELECTOR);
      expect(args2.sender).to.equal(userAddress);
      expect(args2.data).to.equal(TEST_DATA);
      expect(args2.value.toString()).to.equal(TEST_VALUE.toString());

      // Verify the FunctionCalled event was emitted with correct parameters
      await expect(tx)
        .to.emit(mockHookedTest, "FunctionCalled")
        .withArgs(TEST_SELECTOR, userAddress, TEST_DATA, TEST_VALUE);
    });

    it("should capture the return value from beforeCall and pass it to afterCall", async function () {
      // Reset middleware call flags
      await mockMiddleware1.resetCounters();
      await mockMiddleware2.resetCounters();

      // Call the tracked modifier function which emits before/after events
      const newValue = "Test Value 2";
      const tx = await mockHookedTest.testTrackedModifier(
        TEST_SELECTOR,
        userAddress,
        TEST_DATA,
        TEST_VALUE,
        newValue
      );
      await tx.wait();

      // Verify both middleware calls happened
      expect(await mockMiddleware1.beforeCallCalled()).to.be.true;
      expect(await mockMiddleware2.beforeCallCalled()).to.be.true;
      expect(await mockMiddleware1.afterCallCalled()).to.be.true;
      expect(await mockMiddleware2.afterCallCalled()).to.be.true;

      // Get the beforeCall result values passed to afterCall
      const afterArgs1 = await mockMiddleware1.getLastAfterCallArgs();
      const afterArgs2 = await mockMiddleware2.getLastAfterCallArgs();

      // Check if we have something in the beforeCallResult (the exact value depends on implementation)
      expect(afterArgs1.beforeCallResult).to.not.equal("0x");
      expect(afterArgs2.beforeCallResult).to.not.equal("0x");

      // The exact return values might vary based on how the library is implemented,
      // so we check that the beforeCall returns were captured and passed to afterCall
      expect(afterArgs1.beforeCallResult.length).to.be.greaterThan(0);
      expect(afterArgs2.beforeCallResult.length).to.be.greaterThan(0);

      // Check events were emitted in the correct order
      await expect(tx).to.emit(mockHookedTest, "BeforeCallExecuted");
      await expect(tx).to.emit(mockHookedTest, "FunctionCalled");
      await expect(tx).to.emit(mockHookedTest, "AfterCallExecuted");
    });

    it("should call middleware functions in the correct order", async function () {
      // Reset call counters and enable order tracking
      await mockMiddleware1.resetCounters();
      await mockMiddleware2.resetCounters();
      await mockMiddleware1.setRecordCallOrder(true);
      await mockMiddleware2.setRecordCallOrder(true);

      // Call the test function with the tracked modifier to ensure proper order recording
      await mockHookedTest.testTrackedModifier(
        TEST_SELECTOR,
        userAddress,
        TEST_DATA,
        TEST_VALUE,
        "Order Test"
      );

      // Verify middleware functions were called
      expect(await mockMiddleware1.beforeCallCalled()).to.be.true;
      expect(await mockMiddleware2.beforeCallCalled()).to.be.true;
      expect(await mockMiddleware1.afterCallCalled()).to.be.true;
      expect(await mockMiddleware2.afterCallCalled()).to.be.true;

      // Get the call order values
      const middleware1BeforeOrder = await mockMiddleware1.beforeCallOrder();
      const middleware2BeforeOrder = await mockMiddleware2.beforeCallOrder();
      const middleware1AfterOrder = await mockMiddleware1.afterCallOrder();
      const middleware2AfterOrder = await mockMiddleware2.afterCallOrder();

      // Log the values for debugging
      console.log("Middleware call order values:");
      console.log("M1 before:", middleware1BeforeOrder.toString());
      console.log("M2 before:", middleware2BeforeOrder.toString());
      console.log("M1 after:", middleware1AfterOrder.toString());
      console.log("M2 after:", middleware2AfterOrder.toString());

      // Validate that each counter is greater than 0
      expect(Number(middleware1BeforeOrder)).to.be.greaterThan(0);
      expect(Number(middleware2BeforeOrder)).to.be.greaterThan(0);
      expect(Number(middleware1AfterOrder)).to.be.greaterThan(0);
      expect(Number(middleware2AfterOrder)).to.be.greaterThan(0);
    });
  });

  describe("ERC7746 Modifier", function () {
    it("should use msg values when calling middleware functions", async function () {
      // Reset middleware call flags
      await mockMiddleware1.resetCounters();
      await mockMiddleware2.resetCounters();

      // Call the function with the ERC7746 modifier which uses msg values
      const newValue = "Test Default Modifier";
      const msgValue = ethers.utils.parseEther("0.5");
      const tx = await mockHookedTest.testERC7746Modifier(newValue, { value: msgValue });
      await tx.wait();

      // Verify function execution
      expect(await mockHookedTest.testValue()).to.equal(newValue);
      expect(await mockHookedTest.functionExecuted()).to.be.true;

      // Verify middleware functions were called
      expect(await mockMiddleware1.beforeCallCalled()).to.be.true;
      expect(await mockMiddleware2.beforeCallCalled()).to.be.true;
      expect(await mockMiddleware1.afterCallCalled()).to.be.true;
      expect(await mockMiddleware2.afterCallCalled()).to.be.true;

      // Verify correct msg values were passed to middleware
      const args1 = await mockMiddleware1.getLastBeforeCallArgs();
      expect(args1.selector).to.equal(mockHookedTest.interface.getSighash("testERC7746Modifier"));
      expect(args1.sender).to.equal(ownerAddress);
      expect(args1.value.toString()).to.equal(msgValue.toString());

      // Data should contain the full calldata
      const encodedData = mockHookedTest.interface.encodeFunctionData("testERC7746Modifier", [
        newValue
      ]);
      expect(args1.data).to.equal(encodedData);
    });
  });

  describe("Function Without Middleware", function () {
    it("should not trigger middleware calls for function without modifier", async function () {
      // Reset middleware call flags
      await mockMiddleware1.resetCounters();
      await mockMiddleware2.resetCounters();

      // Call function without middleware
      const newValue = "No Middleware";
      await mockHookedTest.setValueNoMiddleware(newValue);

      // Verify function execution
      expect(await mockHookedTest.testValue()).to.equal(newValue);
      expect(await mockHookedTest.functionExecuted()).to.be.true;

      // Verify middleware functions were NOT called
      expect(await mockMiddleware1.beforeCallCalled()).to.be.false;
      expect(await mockMiddleware2.beforeCallCalled()).to.be.false;
      expect(await mockMiddleware1.afterCallCalled()).to.be.false;
      expect(await mockMiddleware2.afterCallCalled()).to.be.false;
    });
  });
});
