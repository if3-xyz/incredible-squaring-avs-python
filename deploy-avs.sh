#!/bin/bash

# Exit on error
set -e

# Check if .env file exists, if not create it
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << EOL
RPC_URL="http://localhost:8545"
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
EOL
fi

# Install dependencies and deploy
cd avs-contracts
echo "Installing dependencies..."
forge install

echo "Deploying AVS contracts..."
source ../.env && forge script script/IncredibleSquaringDeployer.s.sol \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast
    -vvvv

echo "AVS deployment complete!"
echo "Contract addresses have been saved to the deployment output"
echo "Make sure your EigenLayer node is running before deploying the AVS" 
