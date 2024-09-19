import { task } from "hardhat/config";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-abi-exporter";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
import "hardhat-deploy";
import "solidity-docgen";
// import "@nomicfoundation/hardhat-verify";
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

export default {
  docgen: {
    outputDir: "./docs/contracts",
    pages: "single",
    sourcesDir: "./src",
    pageExtension: ".md",
    exclude: ["mocks", "initializers", "vendor", "modifiers", "fixtures"],
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 21,
    token: "MATIC",
    gasPriceApi: "https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice",
    enabled: false,
    coinmarketcap: process.env.COINMARKETCAP_KEY,
  },
  namedAccounts: {
    deployer: {
      hardhat: "0xF52E5dF676f51E410c456CC34360cA6F27959420",
      arbitrum: "0x5F997aAb4F6757FAa48e008faa599841947959F1",
      anvil: "0x6Cf8d74C7875de8C2FfB09228F4bf2A21b25e583",
      default: "0xF52E5dF676f51E410c456CC34360cA6F27959420", //TODO this must be set for networks
    },
    owner: {
      default: "0x520E00225C4a43B6c55474Db44a4a44199b4c3eE",
      anvil: "0x507c2d32185667156de5B4C440FEEf3800078bDb",
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      accounts: {
        mnemonic: "casual vacant letter raw trend tool vacant opera buzz jaguar bridge myself",
      }, // ONLY LOCAL
    },
    arbitrum: {
      url: process.env.RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY && [process.env.PRIVATE_KEY],
    },
    mumbai: {
      url: "https://matic-mumbai.chainstacklabs.com",
      accounts: process.env.PRIVATE_KEY && [process.env.PRIVATE_KEY],
    },
    matic: {
      url: process.env.RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY && [process.env.PRIVATE_KEY],
    },
    ganache: {
      url: process.env.GANACHE_RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY && [process.env.PRIVATE_KEY],
    },
    goerli: {
      url: process.env.RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY && [process.env.PRIVATE_KEY],
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      accounts: {
        mnemonic: "casual vacant letter raw trend tool vacant opera buzz jaguar bridge myself",
      }, // ONLY LOCAL
    },
    anvil: {
      url: process.env.ANVIL_RPC_URL ?? "",
      accounts: {
        mnemonic: process.env.ANVIL_MNEMONIC ?? "x",
      },
    },
  },
  paths: {
    sources: "./src",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200000,
          },
        },
      },
    ],
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
    alwaysGenerateOverloads: true, // should overloads with full signatures like deposit(uint256) be generated always, even if there are no overloads?
    // externalArtifacts: ["externalArtifacts/*.json"], // optional array of glob patterns with external artifacts to process (for example external libs from node_modules)
  },
  abiExporter: {
    path: "./abi",
    runOnCompile: true,
    clear: true,
    format: "json",
    // flat: true,
    // only: [":ERC20$"],
    spacing: 2,
    pretty: false,
  },
};
