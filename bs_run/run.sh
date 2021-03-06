#!/bin/bash

#removes any existing output files from previous runs
rm -R simulations/defaultRun/output/*
mkdir simulations/defaultRun/output/heatmap/

rm -R simulations/roadTest/output/*
mkdir simulations/roadTest/output/heatmap/

rm -R simulations/S1/output/*
mkdir simulations/S1/output/heatmap/

rm -R simulations/S2/output/*
mkdir simulations/S2/output/heatmap/

rm -R simulations/S3/output/*
mkdir simulations/S3/output/heatmap/

rm -R simulations/S4/output/*
mkdir simulations/S4/output/heatmap/

rm -R simulations/S5/output/*
mkdir simulations/S5/output/heatmap/

java -Xmx2048m -Dfile.encoding=UTF-8 -cp dep/NetLogo.jar \
  org.nlogo.headless.Main \
  --model worms.nlogo \
  --experiment location-2 \
  --threads 3
