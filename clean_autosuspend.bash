#!/bin/bash

pushd ~/android/system
rm -rf out
popd

now=$(date)
echo "$now"
(make || make) && make suspend
echo "Build started: $now"

