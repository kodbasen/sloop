#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $BASEDIR/sloop-common.sh

sloop::init

sloop::main

sloop::turndown
