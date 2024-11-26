#!/bin/bash
#SBATCH -J CPL                # name of the job
#SBATCH -p shared                # name of the partition: available options "standard,standard-low,gpu,gpu-low,hm"
#SBATCH -n 4                    # no of processes or tasks
#SBATCH -t 72:00:00                # walltime in HH:MM:SS, Max value 72:00:00
#SBATCH --cpus-per-task=1            # Number of CPU cores per task
#SBATCH --mem-per-cpu=120G

#SBATCH --mail-user=subhadeepiitkgpcoral@gmail.com        # user's email ID where job status info will be sent
#SBATCH --mail-type=ALL        # Send Mail for all type of event regarding the job

#list of modules you want to use
module load compiler/intel-mpi/mpi-2020-v4
#module load compiler/intel-mpi/mpi-2019-v5



mpirun -np 4 ./padcswan
