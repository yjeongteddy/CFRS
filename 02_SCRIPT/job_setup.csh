#!/bin/csh
cat > job_01.sh << EOF
#!/bin/bash
#SBATCH -J ${TC_NUM}_SU        # JOB_NAME
#SBATCH -o ${TC_NUM}_SU.out    # JOB_STDOUT
#SBATCH -e ${TC_NUM}_SU.err    # JOB_STDOUT
#SBATCH -N 1   		       # NODE
#SBATCH -n 1 		       # PROC[CPU]
#SBATCH -w node9

export OMP_NUM_THREADS=1
ulimit -s unlimited
./swan.exe
EOF

chmod u+x job_01.sh
sbatch --qos=high job_01.sh
