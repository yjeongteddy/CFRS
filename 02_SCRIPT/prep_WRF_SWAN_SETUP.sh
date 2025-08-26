#!/bin/bash
tgt_dir="/home/user_006/01_WORK/2025/NPP/05_DATA/processed/HANBIT/2008_BAVI/13_SETUP/MAX_mod/1.30+10"
if [ -d "$tgt_dir" ]; then
        cd "$tgt_dir"
else
        mkdir -p "$tgt_dir"
	cd "$tgt_dir"
fi
ln -sf /home/user_006/06_MODEL/swan.exe .
ln -sf /home/user_006/01_WORK/2025/NPP/02_SCRIPT 02_SCRIPT
ln -sf 02_SCRIPT/INPUT_SU.csh .
ln -sf 02_SCRIPT/job_setup.csh .
ln -sf 02_SCRIPT/run_script_swan.csh .
ln -sf /home/user_006/01_WORK/2025/NPP/05_DATA/processed/HANBIT/2008_BAVI/10_SWAN/MAX_mod/1.30+10 1.30+10
