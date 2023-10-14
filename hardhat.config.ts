import { HardhatUserConfig } from "hardhat/config";
// import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";

const config: HardhatUserConfig = {
  solidity: "0.8.21",
  namedAccounts: {
    deployer: {
        default: 0, 
        1: 0,
    },
  }
};

export default config;
