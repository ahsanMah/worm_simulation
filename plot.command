#!/bin/bash

python -c "import matplotlib"

if [$? -eq 0]
then
	echo Matplotlib not found
	echo Beginning installation...
	pip install matplotlib
	echo Installation complete!
else
	echo Found matplotlib
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "${DIR}"
cd ${DIR}
./pyScript

