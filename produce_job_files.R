rm(list=ls())

# identify computer and set directories
hostname<-system('hostname',intern=TRUE)

if(strtrim(hostname,8)=='cheyenne'){

  source('/glade/u/home/naddor/scripts/r_scripts/tofu/set_default_paths.R')
  source('/glade/u/home/naddor/scripts/r_scripts/tofu/set_camels_paths.R')
  load_camels_data('2.1') # load CAMELS attributes

} else {

  stop('You are not running this script from cheyenne!')

}

### CREATE JOB FILE
n_cpus<-36 # number of cpus per node
n_nodes<-floor(671/n_cpus)

# select catchments with low area error
camels_topo$rel_area_error<-abs(camels_topo$area_gages2/camels_topo$area_geospa_fabric-1)
camels_topo_rk<-camels_topo[order(camels_topo$rel_area_error,decreasing=FALSE),] # rank catchments by relative error
id_us<-camels_topo_rk[1:(n_cpus*n_nodes),'gauge_id']

qsub_dir<-paste0('/home/naddor/qsub_cheyenne/param_transfer_maurer/',fuse_id,'/')
qsub_dir_ch<-paste0('/glade/u/home/naddor/qsub/param_transfer_maurer/',fuse_id,'/')

if(!dir.exists(qsub_dir)){
  dir.create(qsub_dir)
  dir.create(paste0(qsub_dir,'def/'))
  dir.create(paste0(qsub_dir,'sce/'))
  dir.create(paste0(qsub_dir,'best/'))
}

name_batch_file_def<-paste0(qsub_dir_ch,'def/param_transfer_maurer_',fuse_id,'_def.txt')
name_qsub_file_def<-paste0(qsub_dir,'def/param_transfer_maurer_',fuse_id,'_def.bsh')

name_batch_file_sce<-paste0(qsub_dir_ch,'sce/param_transfer_maurer_',fuse_id,'_sce.txt')
name_qsub_file_sce<-paste0(qsub_dir,'sce/param_transfer_maurer_',fuse_id,'_sce.bsh')

name_batch_file_best<-paste0(qsub_dir_ch,'best/param_transfer_maurer_',fuse_id,'_best.txt')
name_qsub_file_best<-paste0(qsub_dir,'best/param_transfer_maurer_',fuse_id,'_best.bsh')

if(file.exists(name_batch_file_def)){

  system(paste('rm',name_batch_file_def))
  system(paste('rm',name_batch_file_sce))
  system(paste('rm',name_batch_file_best))

}

write('#!\\bin\\sh', name_batch_file_def, append=TRUE)
write('#!\\bin\\sh', name_batch_file_sce, append=TRUE)
write('#!\\bin\\sh', name_batch_file_best, append=TRUE)

for(id in id_us){

  content<-paste0(dir_fuse_bin_ch,'fuse.exe ',dir_fuse_bin_ch,'fm_902_maurer_benchmark_all.txt us_',id,' ',fuse_id,' run_def > us_',id,'_def.out')
  write(content, name_batch_file_def, append=TRUE)

  content<-paste0(dir_fuse_bin_ch,'fuse.exe ',dir_fuse_bin_ch,'fm_902_maurer_benchmark_cal.txt us_',id,' ',fuse_id,' calib_sce > us_',id,'_sce.out')
  write(content, name_batch_file_sce, append=TRUE)

  content<-paste0(dir_fuse_bin_ch,'fuse.exe ',dir_fuse_bin_ch,'fm_902_maurer_benchmark_all.txt us_',id,' ',fuse_id,' run_best > us_',id,'_best.out')
  write(content, name_batch_file_best, append=TRUE)

}

write_qsub(name_qsub_file_def,name_batch_file_def,batch_name=paste0('fp_def_',fuse_id),n_nodes)
write_qsub(name_qsub_file_sce,name_batch_file_sce,batch_name=paste0('fp_sce_',fuse_id),n_nodes)
write_qsub(name_qsub_file_best,name_batch_file_best,batch_name=paste0('fp_best_',fuse_id),n_nodes)
