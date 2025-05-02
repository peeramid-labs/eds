# Versioning

EDS implements a Semantic versioning system within one bytes32 word.

On chain semantic versioning is managed by [LibSemver](../../src/versioning/LibSemver.sol).
Typical on-chain uses:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../../src/interfaces/IRepository.sol";
import "../../src/versioning/LibSemver.sol";
import "../../src/erc7744/LibERC7744.sol";

contract MockRepository is IRepository {
    using LibERC7744 for bytes32;
    using LibSemver for LibSemver.Version;
    using LibSemver for uint256;

    function example(LibSemver.Version memory version, LibSemver.Requirement req) external view {
        uint256 versionUint = version.toUint256();
        LibSemver.Version restoreVersion = versionUint.parse();
        uint64 major = restoreVersion.major;
        uint64 minor = restoreVersion.minor;
        uint128 patch = restoreVersion.patch;
        string memory stringVersion = version.toString();
        bool satisfies = version.compare(req);
    }
}
```
## CLI helpers

> [!NOTE]
> The CLI provides utilities to work with semantic versioning.

```bash
# Convert semver string to uint256 encoded value
eds versioning parse 1.2.3

# Convert uint256 encoded value back to semver string
eds versioning format <uint256-value>

# Compare two versions
eds versioning compare 1.2.3 1.3.0

# Check if version satisfies a requirement
eds versioning satisfies 1.2.3 "^1.0.0"

# Common options available for all commands
--rpc-url <url>       # RPC endpoint
--private-key <key>   # Private key for transactions (when needed)
```
