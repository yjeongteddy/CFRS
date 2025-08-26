#!/bin/bash
#SBATCH -J plot1215
#SBATCH -o plot1215.out
#SBATCH -e plot1215.err
#SBATCH -N 1
#SBATCH -n 6
#SBATCH -w node8

/appl/MATLAB/R2022a/bin/matlab -nodesktop -nodisplay -nosplash -r "addpath(genpath('/home/user_006/08_MATLIB')); PostReSetup('1215_BOLAVEN', 'HANBIT', '1.30+10', '33.8%', '/home/user_006/01_WORK/2025/NPP'); exit;"
