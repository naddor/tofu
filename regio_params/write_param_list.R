# purpose: once calibration has been peformed for indiviual catchments (parameter sets stored in dir_output),
# create list (file_list) with names of all catchments with calibrated parameters to be used by FUSE.

rm(list=ls())

list_fuse<-c('900','902','904')

for (fuse_id in list_fuse){

  dir_output<-paste0('/gpfs/ts0/projects/Research_Project-CLES-00008/camels_us/time_series/output_obs/fuse_output_maurer/output_',fuse_id,'/')
  files_para_best<-system(paste0('ls ',dir_output,'*para_best*'),intern=TRUE)

  file_list<-paste0('/gpfs/ts0/home/na491/fuse/bin/list_param_all_',fuse_id,'.txt')
  if(file.exists(file_list)){file.remove(file_list)}

  for (p in 1:length(files_para_best)){ # loop through calibrated parameter sets

    # retrive station ID from file name
    file_split<-strsplit(files_para_best[p],'/')[[1]]
    file_name<-file_split[length(file_split)]
    station_id<-strsplit(file_name,'_')[[1]][2]

    # skip basins with corrupted NetCDF files
    #if(!station_id%in%c('02235200','04115265','04074950','09378170','10310500','12143600','12381400','12388400')){

      write(file_name,file=file_list,append=TRUE)

    #
  }
}
