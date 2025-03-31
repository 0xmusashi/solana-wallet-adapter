#!/bin/bash

# Exit on error
set -e

echo "Updating package.json files..."

# Find all package.json files in the packages directory
find packages -name "package.json" | while read -r file; do
  echo "Processing $file"
  
  # For macOS, use sed -i '' instead
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # Update package names
    sed -i '' 's/"name": "@solana\/wallet-adapter/"name": "sol-wallet-adapter/g' "$file"
    
    # Update dependencies
    sed -i '' 's/"@solana\/wallet-adapter/"sol-wallet-adapter/g' "$file"
  else
    # Update package names
    sed -i 's/"name": "@solana\/wallet-adapter/"name": "sol-wallet-adapter/g' "$file"
    
    # Update dependencies
    sed -i 's/"@solana\/wallet-adapter/"sol-wallet-adapter/g' "$file"
  fi
done

echo "Package.json updates completed!" 