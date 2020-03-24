write_qsub<-function(qsub_file,cmd_file,batch_name,n_nodes,queue='regular'){

  content<-paste0('#!/bin/bash
# Job Name
#PBS -N ',batch_name,
'\n# Project code
#PBS -A P48500028
#PBS -l walltime=12:00:00
#PBS -q ',queue,'
# Merge output and error files
#PBS -j oe
# Select X nodes, Y CPUs per node
#PBS -l select=',n_nodes,':ncpus=36:mpiprocs=36
# Send email on abort, begin and end
#PBS -m abe
# Specify mail recipient
#PBS -M naddor@ucar.edu

export MPI_SHEPHERD=true

### Run the executable
mpiexec_mpt launch_cf.sh ',cmd_file)

  write(content, qsub_file, append=FALSE)

}
