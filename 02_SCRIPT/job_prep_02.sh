#!/bin/bash
#SBATCH -J gf1315               # Job name
#SBATCH -o gf1315.out           # Stdout
#SBATCH -e gf1315.err           # Stderr
#SBATCH -N 1                    # Number of nodes
#SBATCH -n 96	                # Number of processors
#SBATCH -w node3          # Specific node

/appl/MATLAB/R2022a/bin/matlab -nodesktop -nodisplay -nosplash -r "addpath(genpath('/home/user_006/08_MATLIB')); get_fort1315('2008_BAVI', 'HANBIT', '1.30+10', '10exH+SLR', '3'); exit;"
