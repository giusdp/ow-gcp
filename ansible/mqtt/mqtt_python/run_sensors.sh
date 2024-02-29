#!/bin/bash

#conda activate mqtt

for i in {0..5}
do
	python3 client.py $i &
done
