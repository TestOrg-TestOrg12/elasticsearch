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

git status

git config --global user.name elasticmachine
git config --global user.email '15837671+elasticmachine@users.noreply.github.com'

git add build-tools-internal/version.properties
git commit -m "[Automated] Update Lucene snapshot to $LUCENE_SNAPSHOT_VERSION"
git push origin "$BUILDKITE_BRANCH"
