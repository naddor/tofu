write_qsub<-function(qsub_file,cmd_file,batch_name,project_key,n_nodes,queue='pq'){

  content<-paste0('#!/bin/bash
# Job Name
#PBS -N ',batch_name,
'\n# Project code
#PBS -A ',project_key,'
#PBS -l walltime=12:00:00 # maximum wall time hh:mm:ss
#PBS -q ',queue,'
# Merge output and error files
#PBS -j oe
# Nodes = number of nodes required. ppn=number of processors per node
#PBS -l nodes=',n_nodes,':ppn=16
# Send email on abort, begin and end
#PBS -m abe -M n.addor@exeter.ac.uk

module add impi/2017.3.196-iccifort-2017.4.196-GCC-6.4.0-2.28

export MPI_SHEPHERD=true

### Run the executable
mpirun -bootstrap pbsdsh -f $PBS_NODEFILE -np ',n_nodes*16,' ',cmd_file)

  write(content, qsub_file, append=FALSE)

}
