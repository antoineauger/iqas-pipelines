#!/bin/bash

mvn install:install-file \
   -Dfile=../iqas-platform/target/iqas-platform-1.0-SNAPSHOT-allinone.jar \
   -DgroupId=fr.isae.iqas \
   -DartifactId=iqas-platform \
   -Dversion=1.0-SNAPSHOT \
   -Dpackaging=jar \
   -DgeneratePom=true
