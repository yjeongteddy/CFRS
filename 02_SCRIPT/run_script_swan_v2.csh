#!/bin/bash
s_date=$(head -n 1 WIND_NAMES.dat | sed -E 's#.*/([0-9]{4})-([0-9]{2})-([0-9]{2})_([0-9]{2}).dat#\1\2\3.\40000#')
e_date=$(tail -n 1 WIND_NAMES.dat | sed -E 's#.*/([0-9]{4})-([0-9]{2})-([0-9]{2})_([0-9]{2}).dat#\1\2\3.\40000#')
tgt_tc=$(basename $(dirname $(dirname $(dirname "$(pwd)"))))
tc_num=${tgt_tc%%_*}

cat > run_script_swan.sh << EOF
#!/bin/bash
export sdate=${s_date}
export edate=${e_date}
export TC_NUM=${tc_num}
export nNum=${nNum}

cd /home/user_006/01_WORK/2025/NPP/05_DATA/processed/${TGT_NPP}/${TGT_TC}/10_SWAN/${subdir}/${INTENSITY} 
csh INPUT.csh
csh job_swan.csh
EOF

chmod u+x run_script_swan.sh
./run_script_swan.sh
