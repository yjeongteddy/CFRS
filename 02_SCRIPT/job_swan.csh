#!/bin/csh
cat > job_01.sh << EOF
#!/bin/bash
#SBATCH -J ${TC_NUM}_HS        # JOB_NAME
#SBATCH -o ${TC_NUM}_HS.out    # JOB_STDOUT
#SBATCH -e ${TC_NUM}_HS.err    # JOB_STDOUT
#SBATCH -N 1   		       # NODE
#SBATCH -n 96  		       # PROC[CPU]
#SBATCH -w node${nNum}

export OMP_NUM_THREADS=96
./swan.exe
EOF
chmod u+x job_01.sh

cat > job_02.sh << EOF
#!/bin/bash
#SBATCH -J ${TC_NUM}_PSO       # JOB_NAME
#SBATCH -o ${TC_NUM}_PSO.out   # JOB_STDOUT
#SBATCH -e ${TC_NUM}_PSO.err   # JOB_STDOUT
#SBATCH -N 1                   # NODE
#SBATCH -n 96                  # PROC[CPU]
#SBATCH -w node${nNum}

/appl/MATLAB/R2022a/bin/matlab -nodesktop -nodisplay -nosplash -r "addpath(genpath('/home/user_006/08_MATLIB')); create_wave_ds_robust('.'); exit;"
EOF
chmod u+x job_02.sh

set scripts = ( job_01.sh job_02.sh )

foreach script ($scripts)
    sbatch --qos=high $script
end
