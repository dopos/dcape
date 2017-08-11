#!/bin/bash

# This script called by webhook
# See hooks.json

. hook_lib.sh

# For use inside consup environvent
# add .web.service.consul suffix to repo url
# use true as 2d arg
integrate $1 true

