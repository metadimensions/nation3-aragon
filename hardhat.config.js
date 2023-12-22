require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

const INFURA_API_KEY = process.env.INFURA_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;


module.exports = {
   networks: {
      goerli: {
        url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
        accounts: [PRIVATE_KEY],
        chainId: 5,
        blockConfirmation: 6
      }
    },
    solidity: {
      compilers: [
        {
          version: "0.8.8",
        },
        {
          version: "0.8.20",
        },
      ],
    }
};

