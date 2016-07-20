#!/bin/bash

#removes any existing output files from previous runs
rm -R simulations/defaultRun/output/*
mkdir simulations/defaultRun/output/heatmap/

rm -R simulations/roadTest/output/*
mkdir simulations/roadTest/output/heatmap/

java -Xmx2048m -Dfile.encoding=UTF-8 -cp dep/NetLogo.jar \
  org.nlogo.headless.Main \
  --model worms.nlogo \
  --experiment temp-4 \
  --threads 3
