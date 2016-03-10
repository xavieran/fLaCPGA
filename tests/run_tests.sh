#!/bin/bash

GTEST_OUTPUT=xml:./reports/test_bitreader.xml ./test_bitreader 
junit-viewer --results ./reports/report.xml > ./reports/test_bitreader.html

if [ "$1" = "-v" ] ;then 
	firefox ./reports/test_bitreader.html
fi

