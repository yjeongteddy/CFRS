#!/bin/bash
#SBATCH -J 2008_PUI
#SBATCH -o 2008_PUI.out
#SBATCH -e 2008_PUI.err
#SBATCH -N 1
#SBATCH -n 32
#SBATCH -w node2

/appl/MATLAB/R2022a/bin/matlab -nodesktop -nodisplay -nosplash -r "addpath(genpath('/home/user_006/08_MATLIB')); GetDepthSetup('2008_BAVI', 'HANBIT', '10exH+SLR'); GetWindSetup('2008_BAVI', 'HANBIT', '10exH+SLR'); PrepWaveSetup_v2('2008_BAVI', 'HANBIT', '10exH+SLR'); exit;"
