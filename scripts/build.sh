#!/bin/bash
REPO_DIR="$WORKSPACE/$REPO"

set -e

cd $REPO_DIR
npm install lodash
npm install axis
npm install jeet
npm install rupture
npm install roots
make build
cp -r ./public/* ${BUILDDIR}/${REPO}
