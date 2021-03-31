#!/bin/bash

dirty="$(git status --porcelain -uno 2>/dev/null | wc -l)"

if [ $dirty -gt "0" ]; then
  echo "Please commit your changes before tagging"
  exit
fi

MANIFEST=version

# find current data
curCode=$(cat $MANIFEST | grep code | grep -o "[0-9]\+")
curName=$(cat $MANIFEST | grep name | grep -o '".\+"' | sed -e 's:^.\(.*\).$:\1:')
commit=$(git log -1 --format="%h")

# increment code
newCode=$((curCode + 1))

if [[ $curName =~ ^([0-9]+)\.([0-9]+)$ ]]; then
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  patch=0
elif [[ $curName =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  patch=${BASH_REMATCH[3]}
else
  major=0
  minor=0
  patch=0
fi

# increment version
case "$1" in
  "major")
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  "minor")
    minor=$((minor + 1))
    patch=0
    ;;
  "patch")
    patch=$((patch + 1))
    ;;
  *)
    echo "Please select a tag level: major, minor, patch"
    exit
    ;;
esac

newName="$major.$minor.$patch"

# update manifest
sed -e "s/code=$curCode/code=$newCode/"\
    -e "s/name=\"$curName\"/name=\"$newName\"/"\
    --in-place $MANIFEST

# stage, commit, tag
echo "Bumped from $curCode -> $newCode"
echo "Renamed from $curName -> $newName"
echo "Tagging $newName"
git add $MANIFEST
git commit -m "version: Bump from $curCode/$curName -> $newCode/$newName"
git tag -a "$newName" -m "Release $newCode/$newName"

# package and rename zip
pkg
cp game.love game-${newName}.love
