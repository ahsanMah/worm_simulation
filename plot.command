#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "${DIR}"
cd ${DIR}
#./plotScript
python src_files/plot_src.py

