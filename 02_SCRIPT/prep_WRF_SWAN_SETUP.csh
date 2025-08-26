#!/bin/bash
TGT_TC=${1:-"2008_BAVI"}
INTENSITY=${2:-"1.30+10"}
TGT_NPP=${3:-"HANBIT"}
TGT_SL=${4:-"10exH+SLR"}

case "$TGT_SL" in
    "10exH+SLR")
        subdir="MAX_mod"
        ;;
    "10exL")
        subdir="MIN"
        ;;
    "AHHL")
        subdir=""
        ;;
esac

cat > prep_WRF_SWAN_SETUP.sh << EOF
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
ln -sf /home/user_006/01_WORK/2025/NPP/05_DATA/processed/${TGT_NPP}/${TGT_TC}/10_SWAN/$subdir/${INTENSITY} ${INTENSITY}
EOF

chmod u+x prep_WRF_SWAN_SETUP.sh

./prep_WRF_SWAN_SETUP.sh
