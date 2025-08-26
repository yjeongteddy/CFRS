#!/bin/bash
#SBATCH -J plot2008
#SBATCH -o plot2008.out
#SBATCH -e plot2008.err
#SBATCH -N 1
#SBATCH -n 6
#SBATCH -w node8

/appl/MATLAB/R2022a/bin/matlab -nodesktop -nodisplay -nosplash -r "addpath(genpath('/home/user_006/08_MATLIB')); PostSWAN('2008_BAVI', 'HANBIT', '1.30+10', '10exL_mod', '33.8%'); exit;"
