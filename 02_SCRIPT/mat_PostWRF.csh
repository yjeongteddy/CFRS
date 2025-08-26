#!/bin/bash
TGT_TC=${1:-"2008_BAVI"}
TC_ID=${TGT_TC:0:4}
TGT_NPP=${2:-"HANBIT"}
INTENSITY=${3:-"1.30+10"}
INT_INC=${4:-"33.8%"}
nNum=${5:-"3"}

cat > mat_PostWRF.sh <<EOF
#!/bin/bash
#SBATCH -J plot${TC_ID}
#SBATCH -o plot${TC_ID}.out
#SBATCH -e plot${TC_ID}.err
#SBATCH -N 1
#SBATCH -n 96

/appl/MATLAB/R2022a/bin/matlab -nodesktop -nodisplay -nosplash -r "addpath(genpath('/home/user_006/08_MATLIB')); PostWRF('${TGT_TC}', '${TGT_NPP}', '${INTENSITY}', '${INT_INC}'); exit;"
EOF

chmod u+x mat_PostWRF.sh
sbatch mat_PostWRF.sh

