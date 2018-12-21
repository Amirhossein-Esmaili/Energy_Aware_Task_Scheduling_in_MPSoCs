#!/usr/bin/env bash

NAME=TGFF0
TASK_CNT=10
SEED=3


echo "WARNING: default values will be used for undefined arguments."

if  [ -d $NAME ]; then
	printf "%s already exists. Please specify a different name or remove existing directory.\n" $NAME
	exit
fi

mkdir $NAME
cd $NAME

echo Generating $NAME files >> output.log

# Generate TGFF inputs
python2 ../python/tgff_config_gen.py --filename $NAME.tgffopt --task_cnt $TASK_CNT 1 --seed $SEED

# Generate task graph
tgff $NAME

# Generate OPL inputs
python2 ../python/dat_gen.py --in_file $NAME.tgff --out_file $NAME.dat --label $NAME

echo $NAME files created... >> output.log


echo Starting the CPLEX solver engine >> output.log

# Solve MILP (iSCT)
start=`date +%s`
ln -s ../cplex/iSCT.mod
oplrun iSCT.mod $NAME.dat
end=`date +%s`
echo $NAME"_iSCT" >> output.log
echo $((end-start)) >> output.log

# Solve MILP (Heuristic)
start=`date +%s`
ln -s ../cplex/Heuristic.mod
oplrun Heuristic.mod $NAME.dat
end=`date +%s`
echo $NAME"_Heuristic" >> output.log
echo $((end-start)) >> output.log
