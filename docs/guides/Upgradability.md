# Upgrading contracts with EDS

## Introduction

EDS implements next level abstraction pattern over traditional smart contract upgradeability. It allows to upgrade contracts in a safe and easy way, which is fully owned by the end users, without sacrificing any distributor trust to app nor installer.

## Trust assumptions
Upgradability that is both trusted by end-user and distributor requires careful design. Hence this section describes the trust assumptions that are made by EDS.

In EDS it is assumed that downstream contracts are trusted by upstream contracts by explicitly referring to them. Upstream dependencies are unaware of downstream contracts and do not trust them, however may expose public interfaces that are used by downstream contracts.

**1. Ethereum (blockchain consensus, permission-less) domain:**
- [ERC7744 Indexer](./Indexer.md) is the most upstream in dependency chain within the EDS ecosystem and is the only contract that functionality may be trusted by ALL parties.
- In order for [Distributions](./Distributions.md) may be part of same trust domain they **MUST** use [ERC7744 Indexer](./Indexer.md) to refer code.
**2. Developer domain**:
- [Repositories](./Repositories.md) managed by developers may list any developer owned distributions.
- Distributions that rely on any state or external calls are also developers domain.
- Developers trust [ERC7744 Indexer](./Indexer.md) to refer code and they trust any code they deploy or list on their Repositories.
**3. Distributor domain**:
- Distributor trusts [Distributions](./Distributions.md) or [Repositories](./Repositories.md) he lists.
- Distributor **explicitly** lists [versions](./Versions.md) he supports in case listed source is a [repository](./Repositories.md).
- Distributors allow verification checks and upgrade calls for [versions](./Versions.md) he supports by users and may impose specific business or protocol logic on such downstream contracts.
- Distributors trust [ERC7744 Indexer](./Indexer.md) to refer code.
- Distributors may allow cross-instance calls between apps that they consider to be trusted and enforce these rules via runtime validation.
**4. End user domain**:
- End users trust [Distributors](./Distributors.md) they use.
- End users trust [ERC7744 Indexer](./Indexer.md) to refer code.
- Use [Installer](./Installer.md) to install and upgrade [Distributions](./Distributions.md) and [Repositories](./Repositories.md).

## Runtime validation with ERC7746

Whenever an app calls end-user contract, or anyone attempts to call user-owned application, ERC7746 interface is used to implement [runtime middleware hooks](./Hooks.md).

Dependency graph follows from downstream to upstream up until Distributor:
```
External call:
 before call: App -> Installer -> Distributor  (beforeCall hooks)
 App Call
 After call: Distributor -> Installer -> App (afterCall hooks)
```

## Upgradable distributions
Since double trust assumptions, regular proxies owned by single party are not allowed. Developers **MUST** deploy upgradeable distributions for their app, example of such is [WrappedTransparentUpgradeableProxy](../src/proxies/WrappedTransparentUpgradeableProxy.sol).

Such contracts create upgradable instances of app, which are **owned** by distributor but **access permissions** are managed by Installer. Attempts to call upgradability selectors **MUST** result in ERC7746 hook call to Installer.

This mechanic allows to upgrade app without requiring any changes to distributor, while still allowing to enforce business logic on upgrade.
If user wants to renounce distributor, he can do so, but will not be able to upgrade app anymore, unless distributor transfers ownership to user or new distributor.


## Upgrading

Process of normal upgrade routine is as follows:

1. Distributor lists new upgrade version for a Repository with a specific version.
2. Users calls Installer initialize upgrade via `upgradeApp` function.
3. Installer sets flag that app is in upgrade mode and will call Distributor with `upgradeUserInstance` hook.
4. Distributor validates that upgrade is allowed and that version is listed.
5. Distributor loads migration plan from his storage and executes migration logic.
6. Migration logic one way or another must call upgrade on the app instance, as example in [WrappedTransparentUpgradeableProxy](../src/proxies/WrappedTransparentUpgradeableProxy.sol) it is done by `upgradeToAndCall` function by wrapping standard OpenZeppelin upgrade function.
7. App instance contact **MUST** call back to Installer via `beforeCall` hook.
8. Installer validates that call was allowed by Distributor.
9.  Installer sets flag that app is no longer in upgrade mode.

## Migration plan

`MigrationPlan` is a structure that describes how to migrate from one version to another. It contains:
```solidity
struct MigrationPlan {
    LibSemver.VersionRequirement from;
    LibSemver.VersionRequirement to;
    IMigration migrationContract;
    MigrationStrategy strategy;
}
```
Migration plan is stored in Distributor storage and is used by Distributor to execute migration logic. Migration contract **MUST** implement [IMigration](../src/interfaces/IMigration.sol) interface.

### Migration strategies

Migration plan may use different strategies to migrate from one version to another. There are three strategies:

**1. Call**
Distributor will call migration contract with calldata from migration plan. Migration contract will execute the call and return control flow to Distributor.
Migration contract MAY use repository specified migration scripts, distributor only passes current, new versions and repository address.

**2. Delegatecall**
Distributor will delegate execution from own name to migration contract with calldata from migration plan. Migration contract will execute the call and return control flow to Distributor.
Migration contract MAY use repository specified migration scripts, distributor only passes current, new versions and repository address.

**3. Repository managed**

Migration contract will be deployed by Installer and will be managed by Repository. Distributor will not execute any migration logic, but will only signal Installer to execute migration.

Distributor contract will **DELEGATECALL** to repository specified migration script one by one executing migrations for any major version release between `from` and `to` versions.
Eg. if migrating from v0.0.1 to v3.0.0 Distributor will execute migrations for v1.0.0, v2.0.0 and v3.0.0.

#### Minor version migrations

Distributors may specify migration for minor version migrations.
Repositories may not.

In case if minor version migration is specified, Distributor shall not specify strategy as `RepositoryManaged`.


## Renouncing distributor

Installer may renounce distributor webhooks by calling `function changeDistributor(uint256 appId, IDistributor newDistributor, bytes[] memory appData) external;`

This will allow to transfer ownership to new distributor or to user.

Proper secure installer should ensure this function call has high level of permissions required, so that it cannot be used to bypass security oracle features Distributors may provide.

This function will not only remove records of distributor, but also call distributor hook to remove distributor from app to inform it of change. This hook is to be used by distributors to support break up process and release app control from their side, for example in case of `WrappedTransparentUpgradeableProxy` it will transfer ownership to user or to a new distributor.