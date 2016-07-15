#!/bin/bash

rm -R simulations/defaultRun/output/*
rm -R simulations/roadTest/output/*

java -Xmx2048m -Dfile.encoding=UTF-8 -cp dep/NetLogo.jar \
  org.nlogo.headless.Main \
  --model worms.nlogo \
  --experiment ph-2 \
  --threads 3
