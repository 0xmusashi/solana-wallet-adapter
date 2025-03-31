#!/bin/bash

# Exit on error
set -e

# Ensure you're logged in to npm
# echo "Please ensure you're logged in to npm (run 'npm login' if you're not)"
# read -p "Press enter to continue..."

# # Clean and build
# echo "Cleaning and building packages..."
# pnpm run clean
# pnpm run build

# Publish packages in the correct order
echo "Publishing packages in the correct order..."

# 1. Publish base
echo "Publishing sol-wallet-adapter-base..."
cd packages/core/base
npm publish --access public
cd ../../..

# 2. Publish react
echo "Publishing sol-wallet-adapter-react..."
cd packages/core/react
npm publish --access public
cd ../../..

# 3. Publish base-ui
echo "Publishing sol-wallet-adapter-base-ui..."
cd packages/ui/base-ui
npm publish --access public
cd ../../..

# 4. Publish wallet adapters - iterate through all wallets
echo "Publishing individual wallet adapters..."
for wallet_dir in packages/wallets/*; do
  if [ -d "$wallet_dir" ] && [ "$(basename "$wallet_dir")" != "wallets" ]; then
    echo "Publishing $(basename "$wallet_dir")..."
    cd "$wallet_dir"
    npm publish --access public
    cd ../../..
  fi
done

# 5. Publish wallets (main wallet package)
echo "Publishing sol-wallet-adapter-wallets..."
cd packages/wallets/wallets
npm publish --access public
cd ../../..

# 6. Publish UI packages
echo "Publishing sol-wallet-adapter-react-ui..."
cd packages/ui/react-ui
npm publish --access public
cd ../../..

echo "Publishing sol-wallet-adapter-material-ui..."
cd packages/ui/material-ui
npm publish --access public
cd ../../..

if [ -d "packages/ui/ant-design" ]; then
  echo "Publishing sol-wallet-adapter-ant-design..."
  cd packages/ui/ant-design
  npm publish --access public
  cd ../../..
fi

echo "All packages published successfully!" 