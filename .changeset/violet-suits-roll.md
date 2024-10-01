---
"@peeramid-labs/eds": major
---

# Breaking changes

## Deprecated getMetadata in favor of contractURI

contractURI is more widely used and we want to align with the standard.


## Merged VersionedDistributor into Distributor

Now there is only a single `IDistributor` interface. Distribution creators still have two methods of adding distributions - either by specifying repository address, or by specifying a distribution hash id directly.

The `VersionedDistributor` is now deprecated and will be removed in the next major version.

Instantiation function will now automatically detect if the provided address is a repository or a distribution id and call the appropriate method.

ERC7746 checks will now also automatically detect if the provided address is a repository or a distribution and will enforce version control accordingly.

### Instantiated event

Now emits also a version indexed parameter, arshHash was removed, args are availible as not indexed object in data

## addDistribution for versioned repositories

`addDistribution` now takes `LibSemver.VersionRequirement` as an argument, which is more convenient way to pack both version and requirement in a single argument.

## Repository now requires cURI

The `cURI` is now required for all repositories. This is to ensure that all repositories are compliant with the standard contractURI method

## Reposotory `get` function

Repostory `get` function now takes `LibSemver.VersionRequirement` as an argument, which is more convenient way to pack both version and requirement in a single argument.

## LibSemver.compare

`compare` now takes `LibSemver.VersionRequirement` as an argument, which is more convenient way to pack both version and requirement in a single argument.

## LibSemver compare(version version) -> areEqual

`compare(Version memory _version1, Version memory _version2)` now returns a boolean instead of an integer.