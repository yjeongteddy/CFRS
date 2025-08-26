#!/bin/bash
#SBATCH -J wfIntp               # Job name
#SBATCH -o wfIntp.out           # Stdout
#SBATCH -e wfIntp.err           # Stderr
#SBATCH -N 1                    # Number of nodes
#SBATCH -n 96            	# Number of processors
#SBATCH -w node3          # Specific node

/appl/MATLAB/R2022a/bin/matlab -nodesktop -nodisplay -nosplash -r "addpath(genpath('/home/user_006/08_MATLIB')); SaveWRFSetting('2008_BAVI', 'HANBIT', '/home/user_006/01_WORK/2025/NPP/05_DATA/processed', '1.30+10', 'ADCIRC', '10exH+SLR'); load(fullfile('/home/user_006/01_WORK/2025/NPP/05_DATA/processed', 'HANBIT', '2008_BAVI', '12_ADCIRC', 'MAX', '1.30+10', 'settings.mat')); get_WRF_WIND_robust(setting); exit;"
