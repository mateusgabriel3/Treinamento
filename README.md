# How to Install

## Ethereum smart contract

Inside the `axia` directory, contains a [Truffle Framework](https://truffleframework.com) project. So you can do all Truffle operations.

Installation of local dependencies:
```
$ yarn
```

### Deployment

Configure your network node inside the `truffle.js` configuration file and run the migration:
```
$ yarn migrate
```

### Testing

You need to keep your [Ganache](https://truffleframework.com/ganache) (it is possible, instead to use [Ganache CLI](https://github.com/trufflesuite/ganache-cli) if you like) node up and running on `port 8545`. It is recommended to have `100+ ETH` in the first account to run all the test cases smoothly.
```
$ yarn test
```

Or you can run it automatically:
```
$ yarn build:test
```

### Coverage

To get coverage statistics, just run the coverage script:
```
$ yarn build:coverage
```

Solidity version: `v0.5.0+commit.1d4f565a`.
```

Primeiro passos:

- truffle test
- truffle compile
	-> compila os arquivos sol
	-> ABI CODE
- truffle migrate
	-> compilar os arquivos sol
	-> conectar na rede destino
	-> publicar o contrato na rede destino
	
Onde encontrar as redes: https://chainlist.org/
geth - https://geth.ethereum.org/downloads/
faucet - https://faucet.rinkeby.io/
base de contratos: https://github.com/OpenZeppelin/openzeppelin-contracts

Criar uma conta: geth account new
	Pode-se usar os parâmetros extras:
	--datadir : Data directory for the databases and keystore
	--password : password file  
	Exemplo: geth account new --datadir . --password C:\Wander\Pessoal\Axia\ethereum\private\password.sec

Como executar  os comandos:

geth --network rinkeby --syncmode "light"  --rpc --rpcaddr "127.0.0.1" --rpccorsdomain "*" --rpcport "8545" --rpcapi "db, eth, net, web3, personal" --maxpeers=100 --cache=2048
// Esses parâmetros vem depois da criação da conta
 --unlock 0xded8def254271c9768d99e34a826144999a55fad --allow-insecure-unlock
	No Window pode-se ser necessário executar os comandos http em substituição ao rcp, exemplo:
	geth --networkid 4224 --mine --miner.threads 1 --datadir . --nodiscover --http --http.port "8545" --port "30303" --http.corsdomain "*" --nat "any" --http.api eth,web3,personal,net,miner --unlock 0 --password C:\Wander\Pessoal\Axia\ethereum\private\password.sec --allow-insecure-unlock 

truffle console ->

let instance = await TorreToken.deployed();
instance.transfer('0xded8def254271c9768d99e34a826144999a55fad', "100000000000000000");
instance.getBalanceOf('0xded8def254271c9768d99e34a826144999a55fad');

$HOME/.ethereum/rinkeby/accounts/ded8def254271c9768d99e34a826144999a55fad/ded8def254271c9768d99e34a826144999a55fad.pass
				main/accounts/
````
![geth](/axia/img/geth.jpg)
