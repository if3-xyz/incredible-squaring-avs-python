#!/bin/bash

# Exit on error
set -e

export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export RPC_URL=http://localhost:8545

# Install dependencies and deploy
cd contracts
echo "Installing dependencies..."
forge install

echo "Deploying contracts..."
forge script script/IncredibleSquaringDeployer.s.sol \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --sig "run()"

echo "Deployment complete!"
