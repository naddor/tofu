#!/bin/bash

# activate environment
conda activate tofu_python

# example
python3 calc_sim_evpot_oudin.py \
-d /folder1/ERA5_swarm_domain_daily_1979_2019.nc \
-o /folder2/pet-oudin_ERA5_swarm_domain_daily_1979_2019.nc \
-v t2m

# get help
python3 /gpfs/home/hmj19qmu/SWARM-PE/py-scripts/calc_sim_evpot_oudin.py --help
