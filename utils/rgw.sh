#!/bin/bash

cd "$(dirname $0)"

if [[ ! -e .tmp_tc_name ]]; then
    exit 1
fi

docker exec $(cat .tmp_tc_name) radosgw-admin $@
