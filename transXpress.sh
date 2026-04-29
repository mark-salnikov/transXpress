#!/bin/bash
#SBATCH --nodes=1
#SBATCH --partition=langlois-node1
#SBATCH --ntasks=1
#SBATCH --time=96:00:00
#SBATCH --mail-type=ALL
#SBATCH --mem=64g
#SBATCH --mail-user=salni002@umn.edu

# This script has been failing to activate the correct conda envs. Adding this to fix.
source /common/software/install/migrated/anaconda/miniconda3_4.8.3-jupyter/etc/profile.d/conda.sh
conda activate transxpress

# Adding an unlock for running the pipeline multiple times in the same folder.
snakemake --unlock

echo "Running the transXpress pipeline using snakemake"

CLUSTER="NONE"

if [ ! -z `which sbatch 2>/dev/null` ]; then
  CLUSTER="SLURM"
fi

if [ ! -z `which bsub 2>/dev/null` ]; then
  CLUSTER="LSF"
fi

if [ ! -z `which qsub 2>/dev/null` ]; then
  CLUSTER="PBS"
fi

case "$CLUSTER" in
"LSF")
  echo "Submitting snakemake jobs to LSF cluster"
  snakemake --conda-frontend conda --use-conda --latency-wait 60 --restart-times 1 --jobs 10000 --cluster "bsub -oo {log}.bsub -n {threads} -R rusage[mem={params.memory}000] -R span[hosts=1]" "$@"
  ;;
"SLURM")
  echo "Submitting snakemake jobs to SLURM cluster"
  snakemake --conda-frontend conda --use-conda --latency-wait 60 --restart-times 1 --jobs 10000 --cluster "sbatch -o {log}.slurm.out -e {log}.slurm.err -n {threads} --partition=langlois-node1 --mem {params.memory}GB --time 24:00:00" "$@"
  ;;
"PBS")
  echo "Submitting snakemake jobs to PBS/Torque cluster"
  snakemake --conda-frontend conda --use-conda --latency-wait 60 --restart-times 1 --jobs 10000 --cluster "qsub -o {log}.slurm.out -e {log}.slurm.err -l select=1:ncpus={threads}:mem={params.memory}gb" "$@"
  ;;
*)
  snakemake --conda-frontend conda --use-conda --cores all "$@"
  ;;
esac