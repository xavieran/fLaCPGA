#!/bin/bash

cat m.txt | xargs ./read_residual $1 > $2

