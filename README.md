# testnet

forge script --rpc-url https://conflux-espace-testnet.rpc.thirdweb.com/ script/script.s.sol:DeployScript --broadcast --legacy --skip-simulation --verifier-url https://evmapi-testnet.confluxscan.io/api/? --verify --slow --retries 100 --delay 30

add --resume to rerun the previous failure.

# local test

forge script --rpc-url [http://127.0.0.1:8545](http://127.0.0.1:8545/) script/script.s.sol:DeployScript --broadcast --legacy --slow

forge create src/MyPool.sol:MyPool --rpc-url [http://127.0.0.1:8545](http://127.0.0.1:8545/) --private-key [your private key here] --legacy