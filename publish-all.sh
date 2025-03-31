#!/bin/bash

# Don't exit on error - continue with remaining packages
set +e

# Create a log file for errors
error_log="publish-errors.log"
> "$error_log"  # Clear the error log

# Default version increment type
VERSION_INCREMENT=${1:-"patch"}  # Options: major, minor, patch

# Function to increment version
increment_version() {
  local version=$1
  local increment_type=$2
  
  IFS='.' read -ra VERSION_PARTS <<< "$version"
  local major=${VERSION_PARTS[0]}
  local minor=${VERSION_PARTS[1]}
  local patch=${VERSION_PARTS[2]}
  
  case "$increment_type" in
    "major")
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    "minor")
      minor=$((minor + 1))
      patch=0
      ;;
    "patch"|*)
      patch=$((patch + 1))
      ;;
  esac
  
  echo "$major.$minor.$patch"
}

# Function to update dependency versions in all package.json files
update_dependency_versions() {
  local package_name=$1
  local new_version=$2
  
  echo "Updating dependencies for $package_name to version $new_version..."
  
  # Find all package.json files that might have this dependency
  find packages -name "package.json" | while read -r file; do
    # Check if the file contains the package as a dependency
    if grep -q "\"$package_name\":" "$file"; then
      echo "Updating $package_name in $file to version $new_version"
      
      # For macOS, use sed -i '' instead
      if [[ "$OSTYPE" == "darwin"* ]]; then
        # Update both dependencies and devDependencies
        sed -i '' "s/\"$package_name\": \"[^\"]*\"/\"$package_name\": \"^$new_version\"/g" "$file"
      else
        sed -i "s/\"$package_name\": \"[^\"]*\"/\"$package_name\": \"^$new_version\"/g" "$file"
      fi
    fi
  done
}

# Get current version from a package.json file
get_current_version() {
  # Check if packages/core/base/package.json exists
  if [ -f "packages/core/base/package.json" ]; then
    local version=$(grep -o '"version": "[^"]*"' "packages/core/base/package.json" | cut -d'"' -f4)
    echo "$version"
  else
    echo "0.1.1"  # Default if file not found
  fi
}

# Get the current version and increment it
CURRENT_VERSION=$(get_current_version)
NEW_VERSION=$(increment_version "$CURRENT_VERSION" "$VERSION_INCREMENT")

echo "Current version: $CURRENT_VERSION"
echo "New version: $NEW_VERSION"
echo "Incrementing version: $VERSION_INCREMENT"

read -p "Are you sure you want to publish with version $NEW_VERSION? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Publishing canceled."
  exit 1
fi

# Ensure you're logged in to npm
echo "Please ensure you're logged in to npm (run 'npm login' if you're not)"
read -p "Press enter to continue..."

# Clean and build
echo "Cleaning and building packages..."
pnpm run clean
pnpm run build

# Update versions in all package.json files
echo "Updating all packages to version $NEW_VERSION..."
find packages -name "package.json" | while read -r file; do
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/\"version\": \"[0-9]*\.[0-9]*\.[0-9]*\"/\"version\": \"$NEW_VERSION\"/g" "$file"
  else
    sed -i "s/\"version\": \"[0-9]*\.[0-9]*\.[0-9]*\"/\"version\": \"$NEW_VERSION\"/g" "$file"
  fi
done

# Also update the main package.json
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/\"version\": \"[0-9]*\.[0-9]*\.[0-9]*\"/\"version\": \"$NEW_VERSION\"/g" package.json
else
  sed -i "s/\"version\": \"[0-9]*\.[0-9]*\.[0-9]*\"/\"version\": \"$NEW_VERSION\"/g" package.json
fi

# Replace workspace references with actual version
echo "Replacing workspace references with version numbers..."
find packages -name "package.json" | while read -r file; do
  echo "Processing $file for publishing"
  
  # For macOS, use sed -i '' instead
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # Replace workspace:^ with ^NEW_VERSION
    sed -i '' "s/\"workspace:\^\"/'\"^$NEW_VERSION\"/g" "$file"
  else
    # Replace workspace:^ with ^NEW_VERSION
    sed -i "s/\"workspace:\^\"/'\"^$NEW_VERSION\"/g" "$file"
  fi
done

# Function to publish a package with error handling
publish_package() {
  local package_path=$1
  local package_name=$(basename "$package_path")
  
  echo "Publishing $package_name version $NEW_VERSION..."
  cd "$package_path"
  
  # Try to publish and capture any errors
  if npm publish --access public; then
    echo "✅ Successfully published $package_name@$NEW_VERSION"
    # After successful publish, update dependencies in other packages
    update_dependency_versions "$package_name" "$NEW_VERSION"
  else
    echo "❌ Failed to publish $package_name@$NEW_VERSION" | tee -a "../../$error_log"
  fi
  
  cd - > /dev/null  # Return to previous directory quietly
}

# Publish packages in the correct order
echo "Publishing packages in the correct order..."

# 1. Publish base
publish_package "packages/core/base"

# 2. Publish react
publish_package "packages/core/react"

# 3. Publish base-ui
publish_package "packages/ui/base-ui"

# 4. Publish wallet adapters - iterate through all wallets
echo "Publishing individual wallet adapters..."
for wallet_dir in packages/wallets/*; do
  if [ -d "$wallet_dir" ] && [ "$(basename "$wallet_dir")" != "wallets" ]; then
    publish_package "$wallet_dir"
  fi
done

# 5. Publish wallets (main wallet package)
publish_package "packages/wallets/wallets"

# 6. Publish UI packages
publish_package "packages/ui/react-ui"
publish_package "packages/ui/material-ui"

if [ -d "packages/ui/ant-design" ]; then
  publish_package "packages/ui/ant-design"
fi

# Restore workspace references for development
echo "Restoring workspace references..."
find packages -name "package.json" | while read -r file; do
  echo "Restoring $file for development"
  
  # For macOS, use sed -i '' instead
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # Replace ^NEW_VERSION with workspace:^
    sed -i '' "s/\"^$NEW_VERSION\"/\"workspace:\^\"/g" "$file"
  else
    # Replace ^NEW_VERSION with workspace:^
    sed -i "s/\"^$NEW_VERSION\"/\"workspace:\^\"/g" "$file"
  fi
done

# Check if there were any errors
if [ -s "$error_log" ]; then
  echo "------------------------"
  echo "⚠️ Some packages failed to publish. See the error log below:"
  cat "$error_log"
  echo "------------------------"
  echo "You may need to manually publish these packages."
else
  echo "🎉 All packages published successfully with version $NEW_VERSION!"
fi

# Create git tag for this release
echo "Creating git tag for version $NEW_VERSION"
git add .
git commit -m "Release version $NEW_VERSION"
git tag "v$NEW_VERSION"
echo "Run 'git push --follow-tags' to push the new version." 