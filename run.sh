#!/bin/bash

cd "${0%/*}/.."

export RUST_TEST_THREADS=1

cargo test --features=integration-tests || {
    exit 1
}
