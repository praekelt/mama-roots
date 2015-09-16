#!/bin/bash
REPO_DIR="$WORKSPACE/$REPO"

set -e

cd $REPO_DIR
npm install roots
npm install .
make build
cp -r ./public/* ${BUILDDIR}/${REPO}
