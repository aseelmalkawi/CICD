#!/bin/bash

ARTIFACT_NAME="cicd-shaymaa-${VERSION}-${GITHUB_SHA:0:7}.tgz"
mkdir -p artifacts
mkdir -p artifact-temp
shopt -s extglob
cp -r !(artifact-temp|artifacts|.git|.github) artifact-temp/
tar -czf "artifacts/$ARTIFACT_NAME" -C artifact-temp .
rm -rf artifact-temp
ls -R artifacts