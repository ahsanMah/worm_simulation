#!/bin/bash

java -Xmx2048m -Dfile.encoding=UTF-8 -cp dep/NetLogo.jar \
  org.nlogo.headless.Main \
  --model worms.nlogo \
  --experiment test \
  --threads 3
