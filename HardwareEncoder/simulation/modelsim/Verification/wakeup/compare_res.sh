#!/bin/bash

head -n $1 residuals.txt | tail -n $2  > a
head -n $1 bad_res.txt | tail -n $2 > b
kdiff3 a b
