#!/bin/bash

tests=`ls | grep test*.cpp | sed -s 's/.cpp//'`

for t in $tests; do
	GTEST_OUTPUT=xml:./reports/$t.xml ./$t 
	junit-viewer --results ./reports/$t.xml > ./reports/$t.html

	if [ "$1" = "-v" ] ;then 
		firefox ./reports/$t.html &
	fi
done



