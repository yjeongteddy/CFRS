#!/bin/bash
TGT_TC=${1:-"1913_LINGLING"}
TC_ID=${TGT_TC:0:4}
TGT_NPP=${2:-"HANBIT"}
TGT_SL=${3:-"10exH+SLR"}
nNum=${4:-"2"}

case "$TGT_SL" in
    "10exH+SLR") subdir="MAX_org" ;;
    "10exL")     subdir="MIN" ;;
    "AHHL")      subdir=""    ;;
esac

INTENSITIES=("1.30-10" "1.30" "1.30+10")

for INTENSITY in "${INTENSITIES[@]}"; do

cat > job_01.sh << EOF
#!/bin/bash
tgt_dir="/home/user_006/01_WORK/2025/NPP/05_DATA/processed/${TGT_NPP}/${TGT_TC}/13_SETUP/$subdir/${INTENSITY}"
if [ -d "\$tgt_dir" ]; then
        cd "\$tgt_dir"
else
        mkdir -p "\$tgt_dir"
	cd "\$tgt_dir"
fi
ln -sf /home/user_006/06_MODEL/swan.exe .
ln -sf /home/user_006/01_WORK/2025/NPP/02_SCRIPT 02_SCRIPT
ln -sf 02_SCRIPT/INPUT_SU.csh .
ln -sf 02_SCRIPT/job_setup.csh .
EOF

chmod u+x job_01.sh
bash job_01.sh
rm -f job_01.sh

done

cat > job_02.sh << EOF
#!/bin/bash
#SBATCH -J ${TC_ID}_PUI
#SBATCH -o ${TC_ID}_PUI.out
#SBATCH -e ${TC_ID}_PUI.err
#SBATCH -N 1
#SBATCH -n 96
#SBATCH -w node${nNum}

/appl/MATLAB/R2022a/bin/matlab -nodesktop -nodisplay -nosplash -r "\
addpath(genpath('/home/user_006/08_MATLIB'));\
GetDepthSetup('${TGT_TC}', '${TGT_NPP}', '${TGT_SL}');\
GetWindSetup('${TGT_TC}', '${TGT_NPP}', '${TGT_SL}'); \
PrepWaveSetup_v2_org('${TGT_TC}', '${TGT_NPP}', '${TGT_SL}'); exit;"
EOF

chmod u+x job_02.sh
sbatch job_02.sh
rm -f job_02.sh





