#!/bin/bash

python -c "import matplotlib"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "${DIR}"
cd ${DIR}
./pyScript

