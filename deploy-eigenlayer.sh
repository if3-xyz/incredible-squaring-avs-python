#!/bin/bash

# Exit on error
set -e

# Create a .env file for the deployment
cat > .env << EOL
RPC_URL="http://localhost:8545"
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
EOL

# Install dependencies and deploy
cd eigenlayer-contracts
echo "Installing dependencies..."
forge install

echo "Deploying contracts..."
source ../.env && forge script script/deploy/local/deploy_from_scratch.slashing.s.sol \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --sig "run(string memory configFile)" \
    -- local/deploy_from_scratch.slashing.anvil.config.json

echo "Deployment complete!"

# Ensure the target directory exists
mkdir -p ../avs-contracts/script/output/31337

# Copy the deployment data
cp script/output/devnet/SLASHING_deploy_from_scratch_deployment_data.json ../avs-contracts/script/output/31337/eigenlayer_deployment_output.json

echo "Contract addresses have been saved to avs-contracts/script/output/31337/eigenlayer_deployment_output.json"
