#!/bin/bash
PPWD=$(pwd)
rm -rf ${HOME}/.feat/cache/*
../wiki/stopWiki.sh
cd ../wiki/
./startWiki.sh 2> /dev/null
cd ${PPWD}
coffee feat.coffee
../wiki/stopWiki.sh
sleep 3
