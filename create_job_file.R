
### CREATE JOB FILE

set.seed(42)

id_es<-lat_lon_es$gauge_id[sample(1:dim(lat_lon_es)[1],dim(lat_lon_es)[1])]
id_uk<-lat_lon_uk$gauge_id[sample(1:dim(lat_lon_uk)[1],dim(lat_lon_uk)[1])]
id_us<-camels_clim$gauge_id[(order(camels_clim$frac_snow,decreasing=TRUE))[1:(3*36)]] # catchments with greatest snow fraction

### ALL

qsub_dir<-'/home/naddor/qsub_cheyenne/'

name_batch_file_def<-paste0(qsub_dir,'fusex_us_snow_def.txt')
name_batch_file_sce<-paste0(qsub_dir,'fusex_us_snow_sce.txt')
name_batch_file_best<-paste0(qsub_dir,'fusex_us_snow_best.txt')

if(file.exists(name_batch_file_def)){

  system(paste('rm',name_batch_file_def))
  system(paste('rm',name_batch_file_sce))
  system(paste('rm',name_batch_file_best))

}

write('#!\\bin\\sh', name_batch_file_def, append=TRUE)
write('#!\\bin\\sh', name_batch_file_sce, append=TRUE)
write('#!\\bin\\sh', name_batch_file_best, append=TRUE)

fuse_id=902 # VIC WITH SNOW

for(id in id_us){

  content<-paste0('/glade/u/home/naddor/fuse/bin/fuse_snow_dist_catch.exe us_',id,' ',fuse_id,' 1 run_def > us_',id,'_def.out')
  write(content, name_batch_file_def, append=TRUE)

  content<-paste0('/glade/u/home/naddor/fuse/bin/fuse_snow_dist_catch.exe us_',id,' ',fuse_id,' 1 calib_sce > us_',id,'_',fuse_id,'_sce.out')
  write(content, name_batch_file_sce, append=TRUE)

  content<-paste0('/glade/u/home/naddor/fuse/bin/fuse_snow_dist_catch.exe us_',id,' ',fuse_id,' 1 run_best > us_',id,'_',fuse_id,'_best.out')
  write(content, name_batch_file_best, append=TRUE)

}
