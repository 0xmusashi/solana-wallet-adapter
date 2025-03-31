#!/bin/bash

# Exit on error
set -e

echo "Updating import statements in all TypeScript and JavaScript files..."

# Find all TypeScript and JavaScript files in the packages directory
find packages -type f -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" | while read -r file; do
  # Replace import statements using sed
  # This replaces:
  # 1. import statements: from '@solana/wallet-adapter-X' to 'sol-wallet-adapter-X'
  # 2. export statements: from '@solana/wallet-adapter-X' to 'sol-wallet-adapter-X'
  # 3. require statements: require('@solana/wallet-adapter-X') to require('sol-wallet-adapter-X')
  
  echo "Processing $file"
  
  # For macOS, use sed -i '' instead
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/['\"]@solana\/wallet-adapter-/\'sol-wallet-adapter-/g" "$file"
  else
    sed -i "s/['\"]@solana\/wallet-adapter-/\'sol-wallet-adapter-/g" "$file"
  fi
done

echo "Import statement updates completed!" 