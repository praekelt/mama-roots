#!/bin/bash
REPO_DIR="$WORKSPACE/$REPO"

cd $REPO_DIR
npm install lodash
npm install roots
make build
cp -r ./public/* ${BUILDDIR}/${REPO}
