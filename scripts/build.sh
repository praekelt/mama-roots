#!/bin/bash
REPO_DIR="$WORKSPACE/$REPO"

set -e

cd $REPO_DIR
npm install roots
npm install .
make build
mv ./public ${BUILDDIR}/${REPO}
