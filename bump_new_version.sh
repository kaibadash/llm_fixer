#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

# ~/.gem/credentials
if [ ! -f ~/.gem/credentials ]; then
  echo "Error: ~/.gem/credentials not found. Please set up your RubyGems credentials."
  exit 1
fi

PROJECT_NAME="llm_fixer"
GITHUB_REPO="kaibadash/llm_fixer"
VERSION=$1
echo "Start bumping version: $VERSION"

# Publish
# Add release branch
git checkout main
git checkout -b release/$VERSION
sed -i '' "s/VERSION = \".*\"/VERSION = \"$VERSION\"/" lib/$PROJECT_NAME/version.rb
git commit -am "Bump version $VERSION"

# Publish to rubygems
gem build $PROJECT_NAME.gemspec
bundle install
gem push $PROJECT_NAME-$VERSION.gem

# GitHub release
git tag $VERSION
git push --tags
open https://github.com/$GITHUB_REPO/releases/new

# merge to main
git checkout main
git merge release/$VERSION

