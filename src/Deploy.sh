#!/bin/bash

# testnet
forge script --rpc-url https://conflux-espace-testnet.rpc.thirdweb.com/ script/script.s.sol:DeployScript --broadcast --verify --legacy --skip-simulation --verifier-url https://evmapi-testnet.confluxscan.io/api/?

# local test
forge script --rpc-url http://127.0.0.1:8545 script/script.s.sol:DeployScript --broadcast --legacy