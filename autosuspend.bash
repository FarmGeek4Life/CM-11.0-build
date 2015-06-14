#!/bin/bash

now=$(date)
echo "$now"
(make || make) && make suspend
echo "Build started: $now"

