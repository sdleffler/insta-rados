#!/bin/bash

cd "${0%/*}"

if [[ -e .tmp_tc_name ]]; then
    echo "Stopping docker container: $(docker kill $(cat .tmp_tc_name))"
fi

rm -f .tmp_tc_name
