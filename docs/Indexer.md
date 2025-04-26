# EDS Indexing system

EDS indexer is [ERC7744](https://eips.ethereum.org/EIPS/eip-7744) standard compliant codehash registry that allows immutable code referencing in permission-less manner.

ERC7744 indexer is the most upstream in dependency chain within the EDS ecosystem and is the only contract that functionality may be trusted by ALL parties.

## Deploying indexer

You can deploy indexer on your own by following in standard described deployment steps on any network that supports CREATE2 with specified deployer contract.

Deployment bytecode is available in [artifacts](./artifacts/src/erc7744/ERC7744.sol/ERC7744.json) after building the project and is given here for reference:

## Using indexer

!!!WARNING
This section still is WIP, we are implementing a CLI to ease down the deployment process.

[LibERC7744](../src/erc7744/LibERC7744.md) is a library that helps to interact with ERC7744 indexer.

Typical usage is as follows:

```solidity
import {LibERC7744} from "@erc7744/LibERC7744.sol";

function register(address indexer) {
    using LibERC7744 for bytes32;
    using LibERC7744 for address;
    function test(bytes32 codeHash, address newCode)
    {
        address reference = codeHash.getContainer();
        // or to throw on address(0)
        address reference = codeHash.getContainerOrThrow();
        //Register new address in the index:
        codeHash.index(newCode);
    }
}
```

### Off-chain usage

```typescript
const { ethers } = require("ethers");
const { LibERC7744 } = require("@erc7744/LibERC7744.sol");

const code = await ethers.provider.getCode(address);
const codeHash = ethers.utils.keccak256(code);
const address = 0x1234567890123456789012345678901234567890;
const indexer = new ethers.Contract(indexer, [
    "function index(address)",
    "function get(bytes32) view returns (address)",
], provider);
await indexer.index(address);
const reference = await indexer.get(codeHash);
```

## Using CLI

> [!NOTE]
> The CLI provides utilities to interact with the ERC7744 indexer.

```bash
# Deploy a new indexer
eds indexer deploy [--options]

# Get the address registered for a code hash
eds indexer <address> get <codehash>

# Register a contract in the indexer
eds indexer <address> register <contract-address>

# Verify if a code hash matches a contract address
eds indexer <address> verify <codehash> <contract-address>

# Generate the code hash for a contract
eds indexer hash <contract-address>

# Common options available for all commands
--rpc-url <url>       # RPC endpoint
--private-key <key>   # Private key for transactions
--gas-limit <limit>   # Optional gas limit
--gas-price <price>   # Optional gas price
```



