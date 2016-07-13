#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $BASEDIR/slup-common.sh

slup::init

slup::clone_kube_deploy

slup::main

slup::turndown
