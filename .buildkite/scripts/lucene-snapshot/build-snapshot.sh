#!/bin/bash

set -euo pipefail

echo --- Building Lucene snapshot

# TODO custom branches
cd ..
git clone git@github.com:apache/lucene.git --branch main --single-branch --depth 1
cd lucene

REVISION=$(git rev-parse --short HEAD)
echo "Lucene Revision: $REVISION"

./gradlew localSettings
./gradlew clean mavenToLocal -Dversion.suffix="SNAPSHOT-$REVISION" -Dmaven.repo.local="$(pwd)/build/maven-local"

## TODO move aws install to image build
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

aws s3 sync build/maven-local/ "s3://download.elasticsearch.org/lucenesnapshots/$REVISION/" --acl public-read

buildkite-agent meta-data set lucene-snapshot-revision "$REVISION"

cd "$WORKSPACE"

if [[ "${UPDATE_ES_LUCENE_SNAPSHOT:-}" ]]; then
  .buildkite/scripts/lucene-snapshot/update-es-snapshot.sh
fi
