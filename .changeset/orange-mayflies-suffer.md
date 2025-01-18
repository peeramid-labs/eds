---
"@peeramid-labs/eds": major
---

- Removed metadata from compilation artifact
- Renamed CodeIndex artifacts into ERC7744 to be more explicit
- Adjusted tests
- Bumped compilation for ERC7744 to solidity 0.8.28
- Added artifacts to npm package exports to allow 3rd party projects deploy ERC7744 on their own

## Breaking changes 
- ERC7744 Code Index address changes to `0xC0dE1D2F7662c63796E544B2647b2A94EE658E07`
- ICodeIndexRef.sol was removed, you can now directly interface from IERC7744
- ICodeIndex.sol and CodeIndex.sol renamed to IERC7744.sol and ERC7744.sol 

