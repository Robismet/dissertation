#!/bin/bash
set -e
mkdir -p logs
mkdir -p jobscripts/us
# CSV inlezen (komma gescheiden)
while IFS=',' read -r i col2 col3 col4 col5 topol_file index_file; do

    job_name="us-${i}_BDN"
    script_path="jobscripts/us/submit_job-${i}.pbs"

    cat > "$script_path" <<EOF
#!/bin/bash
#PBS -N ${job_name}
#PBS -l walltime=15:00:00
#PBS -l nodes=1:ppn=24:gpus=1
#PBS -o logs/${job_name}.log
#PBS -e logs/${job_name}.err
#PBS -V
module purge
module load vsc-mympirun
module load GROMACS/2021.0-foss-2023a-20250409-constant-pH-CUDA-12.1.1-PLUMED
cd /scratch/gent/vo/000/gvo00003/vsc48847/memb_bdq/Equil/umbrella_unbiased

gmx editconf -f configurations_2/frame_z${i}.gro -o plumed_${i}.pdb

gmx grompp -f step7_production.mdp \
-c configurations_2/frame_z${i}.gro \
-p ${topol_file} \
-n ${index_file} \
-o membrane_bdq_us_pot5-${i}.tpr

gmx mdrun -s membrane_bdq_us_pot5-${i}.tpr \
-deffnm membrane_bdq_us_pot5-${i} \
-plumed plumed_2/plumed_${i}.dat

mkdir -p us-${i}
mv membrane_bdq_us-${i}* us-${i}/
EOF

    echo "Created job script: $script_path"

    if qsub "$script_path"; then
        echo "Submitted job ${job_name}"
    else
        echo "FAILED to submit ${job_name}" >&2
    fi

done < 	umbrella_snapshot_mapping_bdn.csv