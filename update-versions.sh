#!/bin/bash

# Exit on error
set -e

echo "Updating version to 0.1.1 in all package.json files..."

# Find all package.json files in the packages directory
find packages -name "package.json" | while read -r file; do
  echo "Updating version in $file"
  
  # For macOS, use sed -i '' instead
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # Update version to 0.1.1
    sed -i '' 's/"version": "0.1.0"/"version": "0.1.1"/g' "$file"
  else
    # Update version to 0.1.1
    sed -i 's/"version": "0.1.0"/"version": "0.1.1"/g' "$file"
  fi
done

# Also update the main package.json
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' 's/"version": "0.1.0"/"version": "0.1.1"/g' package.json
else
  sed -i 's/"version": "0.1.0"/"version": "0.1.1"/g' package.json
fi

# Update the publish script to use version 0.1.1 instead of 0.1.0
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' 's/"^0.1.0"/"^0.1.1"/g' publish-all.sh
else
  sed -i 's/"^0.1.0"/"^0.1.1"/g' publish-all.sh
fi

echo "Version update completed!" 