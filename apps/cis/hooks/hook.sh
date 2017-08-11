#!/bin/bash

# This script called by webhook
# See hooks.json

. hook_lib.sh

integrate $1 false
