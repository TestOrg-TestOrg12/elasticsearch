#!/bin/bash

set -euo pipefail

echo --- Update Lucene snapshot in Elasticsearch

# TODO ability to pass in
LUCENE_SNAPSHOT_VERSION=$(buildkite-agent meta-data get lucene-snapshot-version)

echo "Lucene Snapshot Version: $LUCENE_SNAPSHOT_VERSION"

git checkout "$BUILDKITE_BRANCH"
git pull --ff-only origin "$BUILDKITE_BRANCH"

# Replace `lucene = <version>` string in version.properties and maintain the same indentation
sed -E "s/^(lucene *= *[^ ]*  *).*\$/\1$LUCENE_SNAPSHOT_VERSION/" build-tools-internal/version.properties > new-version.properties
mv new-version.properties build-tools-internal/version.properties

# Remove stale verification metadata, because generating them just appends new ones
python3 .buildkite/scripts/lucene-snapshot/remove-verification-metadata.py
./gradlew --write-verification-metadata sha256

# 9.8.0-snapshot-1f25c68 -> 9.8.0
VERSION=$(echo "$LUCENE_SNAPSHOT_VERSION" | cut -f 1 -d '-')
VERSION_SNAKE=$(echo "$VERSION" | sed -E 's/\./_/g')

sed -E "s/^(:lucene_version:  *).*\$/\1$VERSION/" docs/Versions.asciidoc > docs/Versions.asciidoc.new
sed -E "s/^(:lucene_version_path:  *).*\$/\1$VERSION_SNAKE/" docs/Versions.asciidoc.new > docs/Versions.asciidoc
rm -f docs/Versions.asciidoc.new

if git diff-index --quiet HEAD --; then
  echo 'No changes to commit.'
else
  git config --global user.name elasticmachine
  git config --global user.email '15837671+elasticmachine@users.noreply.github.com'

  git add build-tools-internal/version.properties
  git add gradle/verification-metadata.xml
  git add docs/Versions.asciidoc

  git commit -m "[Automated] Update Lucene snapshot to $LUCENE_SNAPSHOT_VERSION"
  git push origin "$BUILDKITE_BRANCH"
fi
