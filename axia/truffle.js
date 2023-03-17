const HDWalletProvider = require('truffle-hdwallet-provider');
const Web3 = require('web3');
const fs = require('fs');
const mnemonic = fs.readFileSync(".secret").toString().trim();
module.exports = {
    networks: {
      testnet: {
        provider: () => {
          const data = new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545/`, 0, 100);
          return data
        },        network_id: 97,
        confirmations: 10,
        from: "0xD8f3234C711Dd16ee0d881659d6502161999806d", // default address to use for any transaction Truffle makes during migrations
        timeoutBlocks: 200,
        skipDryRun: true
      }
    }
};