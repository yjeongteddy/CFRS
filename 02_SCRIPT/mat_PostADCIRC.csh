#!/bin/bash
TGT_TC=${1:-"1215_BOLAVEN"}
TC_ID=${TGT_TC:0:4}
TGT_NPP=${2:-"HANBIT"}
TGT_SL=${3:-"10exL_org"}
INTENSITY=${5:-"1.30+10"}
INT_INC=${6:-"33.8%"}
nNum=${7:-"8"}

# Create a temporary SLURM script with the correct output file names.
cat > mat_PostADCIRC.sh << EOF
#!/bin/bash
#SBATCH -J plot${TC_ID}
#SBATCH -o plot${TC_ID}.out
#SBATCH -e plot${TC_ID}.err
#SBATCH -N 1
#SBATCH -n 6
#SBATCH -w node${nNum}

/appl/MATLAB/R2022a/bin/matlab -nodesktop -nodisplay -nosplash -r "addpath(genpath('/home/user_006/08_MATLIB')); PostADCIRC('${TGT_TC}', '${TGT_NPP}', '${INTENSITY}', '${TGT_SL}', '${INT_INC}'); exit;"
EOF

# Make the script executable
chmod u+x mat_PostADCIRC.sh

# Submit the temporary script.
sbatch mat_PostADCIRC.sh

