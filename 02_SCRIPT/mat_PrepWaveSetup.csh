#!/bin/bash
TGT_TC=${1:-"2008_BAVI"}
JOB_NAME=${TGT_TC:0:4}
TGT_NPP=${2:-"HANBIT"}
TGT_SL=${3:-"10exH+SLR"}
nNum=${4:-"2"}

cat > mat_PrepWaveSetup.sh << EOF
#!/bin/bash
#SBATCH -J ${JOB_NAME}_PUI
#SBATCH -o ${JOB_NAME}_PUI.out
#SBATCH -e ${JOB_NAME}_PUI.err
#SBATCH -N 1
#SBATCH -n 32
#SBATCH -w node${nNum}

/appl/MATLAB/R2022a/bin/matlab -nodesktop -nodisplay -nosplash -r "addpath(genpath('/home/user_006/08_MATLIB')); GetDepthSetup('${TGT_TC}', '${TGT_NPP}', '${TGT_SL}'); GetWindSetup('${TGT_TC}', '${TGT_NPP}', '${TGT_SL}'); PrepWaveSetup_v2('${TGT_TC}', '${TGT_NPP}', '${TGT_SL}'); exit;"
EOF

chmod u+x mat_PrepWaveSetup.sh
sbatch mat_PrepWaveSetup.sh

