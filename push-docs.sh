#!/bin/bash

set -o errexit -o nounset

if [ "$TRAVIS_BRANCH" != "master" ]
then
  echo "This commit was made against branch '$TRAVIS_BRANCH' and not 'master'"
  echo "Not deploying!"
  exit 0
fi

rev=$(git rev-parse --short HEAD)

cd doc

git init
git config user.name "Andrew Dunham"
git config user.email "andrew@du.nham.ca"

git remote add upstream "https://$GH_TOKEN@github.com/andrew-d/extika.git"
git fetch upstream
git reset upstream/gh-pages

touch .

git add -A .
git commit -m "rebuild pages at ${rev}"
git push -q upstream HEAD:gh-pages
