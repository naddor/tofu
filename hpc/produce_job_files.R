rm(list=ls())

source(paste(dir_r_scripts,'tofu/hpc/write_qsub_isca.R',sep=''))
source(paste(dir_r_scripts,'tofu/set_camels_paths.R',sep=''))
load_camels_data('2.1') # load CAMELS attributes

### CREATE JOB FILE
fuse_id=900
n_cpus<-16 # number of cpus per node
n_nodes<-floor(671/n_cpus)

# select catchments with low area error
camels_topo_rk<-camels_topo[order(camels_topo$abs_rel_error_area,decreasing=FALSE),] # rank catchments by relative error
id_us<-camels_topo_rk[1:(n_cpus*n_nodes),'gauge_id']

dir_qsub<-paste0('/glade/scratch/naddor/qsub/param_transfer_maurer/',fuse_id,'/')
dir_fuse_bin<-paste0('/glade/u/home/naddor/fuse/bin/')

if(!dir.exists(dir_qsub)){
  dir.create(dir_qsub)
  dir.create(paste0(dir_qsub,'def/'))
  dir.create(paste0(dir_qsub,'sce/'))
  dir.create(paste0(dir_qsub,'best/'))
  dir.create(paste0(dir_qsub,'pre/'))
}

name_batch_file_def<-paste0(dir_qsub,'def/param_transfer_maurer_',fuse_id,'_def.txt')
name_qsub_file_def<-paste0(dir_qsub,'def/param_transfer_maurer_',fuse_id,'_def.bsh')

name_batch_file_sce<-paste0(dir_qsub,'sce/param_transfer_maurer_',fuse_id,'_sce.txt')
name_qsub_file_sce<-paste0(dir_qsub,'sce/param_transfer_maurer_',fuse_id,'_sce.bsh')

name_batch_file_best<-paste0(dir_qsub,'best/param_transfer_maurer_',fuse_id,'_best.txt')
name_qsub_file_best<-paste0(dir_qsub,'best/param_transfer_maurer_',fuse_id,'_best.bsh')

name_batch_file_pre<-paste0(dir_qsub,'pre/param_transfer_maurer_',fuse_id,'_best.txt')
name_qsub_file_pre<-paste0(dir_qsub,'pre/param_transfer_maurer_',fuse_id,'_best.bsh')

write('#!\\bin\\sh',name_batch_file_def,append=FALSE)
write('#!\\bin\\sh',name_batch_file_sce,append=FALSE)
write('#!\\bin\\sh',name_batch_file_best,append=FALSE)
write('#!\\bin\\sh',name_batch_file_pre,append=FALSE)

for(id in id_us){

  content<-paste0(dir_fuse_bin,'fuse.exe ',dir_fuse_bin,'fm_',fuse_id,'_maurer_benchmark_all.txt us_',id,' ',fuse_id,' run_def > us_',id,'_def.out')
  write(content, name_batch_file_def,append=TRUE)

  content<-paste0(dir_fuse_bin,'fuse.exe ',dir_fuse_bin,'fm_',fuse_id,'_maurer_benchmark_cal.txt us_',id,' ',fuse_id,' calib_sce > us_',id,'_sce.out')
  write(content, name_batch_file_sce,append=TRUE)

  content<-paste0(dir_fuse_bin,'fuse.exe ',dir_fuse_bin,'fm_',fuse_id,'_maurer_benchmark_all.txt us_',id,' ',fuse_id,' run_best > us_',id,'_best.out')
  write(content, name_batch_file_best,append=TRUE)

  content<-paste0(dir_fuse_bin,'fuse.exe ',dir_fuse_bin,'fm_',fuse_id,'_maurer_benchmark_all.txt us_',id,' ',fuse_id,' run_pre ',dir_fuse_bin,'list_param_all_',fuse_id,'.txt > us_',id,'_pre.out')
  write(content, name_batch_file_pre,append=TRUE)

}

write_qsub(name_qsub_file_def,name_batch_file_def,batch_name=paste0('fp_def_',fuse_id),n_nodes)
write_qsub(name_qsub_file_sce,name_batch_file_sce,batch_name=paste0('fp_sce_',fuse_id),n_nodes)
write_qsub(name_qsub_file_best,name_batch_file_best,batch_name=paste0('fp_best_',fuse_id),n_nodes)
write_qsub(name_qsub_file_pre,name_batch_file_pre,batch_name=paste0('fp_pre_',fuse_id),n_nodes)
