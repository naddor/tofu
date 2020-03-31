rm(list=ls())

source(paste(dir_r_scripts,'tofu/hpc/write_qsub_isca.R',sep=''))
source(paste(dir_r_scripts,'tofu/set_camels_paths.R',sep=''))
load_camels_data('2.1') # load CAMELS attributes

### CREATE JOB FILE
fuse_id=900
n_cpus<-16 # number of cpus per node
n_nodes<-2

# select catchments
#camels_topo_rk<-camels_topo[order(camels_topo$abs_rel_error_area,decreasing=FALSE),] # rank catchments by relative error
#id_us<-camels_topo_rk[1:(n_cpus*n_nodes),'gauge_id']
id_us<-camels_topo[1:(n_nodes*n_cpus),'gauge_id']

# set dir
dir_qsub<-paste0('/gpfs/ts0/projects/Research_Project-CLES-00008/pbs/test_',fuse_id,'/')
dir_fuse_bin<-paste0('/gpfs/ts0/home/na491/fuse/bin/')

if(!dir.exists(dir_qsub)){
  dir.create(dir_qsub)
  dir.create(paste0(dir_qsub,'def/'))
  dir.create(paste0(dir_qsub,'sce/'))
  dir.create(paste0(dir_qsub,'best/'))
  dir.create(paste0(dir_qsub,'pre/'))
}

# create list of catchments to use as donors
list_donors<-paste0('us_',id_us,'_900_para_best.nc')
file_list_donors<-paste0(dir_fuse_bin,'list_param_900_test.txt')
write(list_donors,file_list_donors,append=FALSE)

# create task and qsub files
name_batch_file_def<-paste0(dir_qsub,'def/param_transfer_maurer_',fuse_id,'_def.txt')
name_qsub_file_def<-paste0(dir_qsub,'def/param_transfer_maurer_',fuse_id,'_def.bsh')

name_batch_file_sce<-paste0(dir_qsub,'sce/param_transfer_maurer_',fuse_id,'_sce.txt')
name_qsub_file_sce<-paste0(dir_qsub,'sce/param_transfer_maurer_',fuse_id,'_sce.bsh')

name_batch_file_best<-paste0(dir_qsub,'best/param_transfer_maurer_',fuse_id,'_best.txt')
name_qsub_file_best<-paste0(dir_qsub,'best/param_transfer_maurer_',fuse_id,'_best.bsh')

name_batch_file_pre<-paste0(dir_qsub,'pre/param_transfer_maurer_',fuse_id,'_pre.txt')
name_qsub_file_pre<-paste0(dir_qsub,'pre/param_transfer_maurer_',fuse_id,'_pre.bsh')

write('#!/bin/sh',name_batch_file_def,append=FALSE)
write('#!/bin/sh',name_batch_file_sce,append=FALSE)
write('#!/bin/sh',name_batch_file_best,append=FALSE)
write('#!/bin/sh',name_batch_file_pre,append=FALSE)

system(paste('chmod a+x',name_batch_file_def))
system(paste('chmod a+x',name_batch_file_best))

for(id in id_us){

  content<-paste0(dir_fuse_bin,'fuse.exe ',dir_fuse_bin,'fm_',fuse_id,'_test_val.txt us_',id,' run_def > ',dir_qsub,'def/us_',id,'_def.out &') # to be run on one core -> &
  write(content, name_batch_file_def,append=TRUE)

  content<-paste0(dir_fuse_bin,'fuse.exe ',dir_fuse_bin,'fm_',fuse_id,'_test_cal.txt us_',id,' calib_sce > ',dir_qsub,'sce/us_',id,'_sce.out')
  write(content, name_batch_file_sce,append=TRUE)

  content<-paste0(dir_fuse_bin,'fuse.exe ',dir_fuse_bin,'fm_',fuse_id,'_test_val.txt us_',id,' run_best > ',dir_qsub,'best/us_',id,'_best.out &') # to be run on one core -> &
  write(content, name_batch_file_best,append=TRUE)

  content<-paste0(dir_fuse_bin,'fuse.exe ',dir_fuse_bin,'fm_',fuse_id,'_test_val.txt us_',id,' run_pre_catch ',file_list_donors,' > ',dir_qsub,'pre/us_',id,'_pre.out')
  write(content, name_batch_file_pre,append=TRUE)

}

write_qsub_isca(name_qsub_file_def,name_batch_file_def,batch_name=paste0('fp_def_',fuse_id),
                project_key=project_key_isca,n_nodes=1,queue='sq',walltime_hours=1)
write_qsub_isca(name_qsub_file_sce,name_batch_file_sce,batch_name=paste0('fp_sce_',fuse_id),
                project_key=project_key_isca,n_nodes,queue='pq',walltime_hours=5)
write_qsub_isca(name_qsub_file_best,name_batch_file_best,batch_name=paste0('fp_best_',fuse_id),
                project_key=project_key_isca,n_nodes=1,queue='sq',walltime_hours=1)
write_qsub_isca(name_qsub_file_pre,name_batch_file_pre,batch_name=paste0('fp_pre_',fuse_id),
                project_key=project_key_isca,n_nodes,queue='pq',walltime_hours=5)
