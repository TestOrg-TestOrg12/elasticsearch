#!/bin/bash

set -euo pipefail

echo --- Building Lucene snapshot

# TODO custom branches
cd ..
git clone git@github.com:apache/lucene.git --branch branch_9x --single-branch --depth 1
cd lucene

LUCENE_SHA=$(git rev-parse --short HEAD)
echo "Lucene Revision: $LUCENE_SHA"

./gradlew localSettings
./gradlew clean mavenToLocal -Dversion.suffix="snapshot-$LUCENE_SHA" -Dmaven.repo.local="$(pwd)/build/maven-local"

LUCENE_SNAPSHOT_VERSION=$(ls -d build/maven-local/org/apache/lucene/lucene-core/*/ | xargs basename)

## TODO move aws install to image build
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

aws s3 sync build/maven-local/ "s3://download.elasticsearch.org/lucenesnapshots/$LUCENE_SHA/" --acl public-read

buildkite-agent meta-data set lucene-snapshot-sha "$LUCENE_SHA"
buildkite-agent meta-data set lucene-snapshot-version "$LUCENE_SNAPSHOT_VERSION"

cd "$WORKSPACE"

if [[ "${UPDATE_ES_LUCENE_SNAPSHOT:-}" ]]; then
  .buildkite/scripts/lucene-snapshot/update-es-snapshot.sh
fi
