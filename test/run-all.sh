#!/bin/bash
set -eu

ROOT=$(readlink -f "$(dirname $0)")

${ROOT}/meta/run-tests.sh
${ROOT}/layer/run-tests.sh
${ROOT}/configurations/run-tests.sh

