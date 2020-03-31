write_qsub_isca<-function(qsub_file,cmd_file,batch_name,project_key,n_nodes=1,queue='pq',walltime_hours){

  pbs_header<-paste0('#!/bin/sh
# Job Name
#PBS -N ',batch_name,
'\n# Project code
#PBS -A ',project_key,'
#PBS -l walltime=',walltime_hours,':00:00 # maximum wall time hh:mm:ss
#PBS -q ',queue,'
# Merge output and error files
#PBS -j oe
# Nodes = number of nodes required. ppn=number of processors per node
#PBS -l nodes=',n_nodes,':ppn=16
# Send email on abort, begin and end
#PBS -m abe -M n.addor@exeter.ac.uk')

  if(queue=='pq'){

    exec_command<-paste0('
module add impi/2017.3.196-iccifort-2017.4.196-GCC-6.4.0-2.28

export MPI_SHEPHERD=true

### Run the executable
mpirun -bootstrap pbsdsh -f $PBS_NODEFILE -np ',n_nodes*16,' ',cmd_file)

  } else if(queue=='sq'){

    exec_command<-paste0('
### Run the executable
',cmd_file)

} else{

  stop(paste('Unexpected queue:',queue))

}

  write(pbs_header, qsub_file, append=FALSE)
  write(exec_command, qsub_file, append=TRUE)

}
