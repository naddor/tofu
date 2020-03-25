rm(list=ls())

list_fuse<-c('900','902','904')
fuse_id<-900

dir_input<-'/gpfs/ts0/projects/Research_Project-CLES-00008/camels_us/time_series/input_obs/input_maurer/'
files_input<-system(paste0('ls ',dir_input,'*input.nc'),intern=TRUE)

file_list<-paste0('/gpfs/ts0/home/na491/fuse/bin/list_param_all_',fuse_id,'.txt')

file_tasks<-paste0('/gpfs/ts0/projects/Research_Project-CLES-00008/pbs/tasks_regio_',fuse_id,'.txt')
if(file.exists(file_tasks)){file.remove(file_tasks)}

dir_bin<-'/gpfs/ts0/home/na491/fuse/bin/'

/gpfs/ts0/home/na491/fuse/bin/fuse.exe /gpfs/ts0/home/na491/fuse/bin/fm_900_maurer_all.txt us_13018300 run_pre_catch /gpfs/ts0/home/na491/fuse/bin/list_files_param_short.txt > /gpfs/ts0/projects/Research_Project-CLES-00008/pbs/regio/log20.txt

for (p in 1:length(files_input)){ # loop through calibrated parameter sets

  # retrive station ID from file name
  file_split<-strsplit(files_input[p],'/')[[1]]
  file_name<-file_split[length(file_split)]
  station_id<-strsplit(file_name,'_')[[1]][2]

  # make command
  cmd<-paste0(dir_bin,'fuse.exe ',dir_bin,'fm_',fuse_id,'_maurer_all.txt us_',station_id,' run_pre_catch ',file_list,' > /gpfs/ts0/projects/Research_Project-CLES-00008/pbs/regio/log',fuse_id,'_',station_id,'.txt')

  write(cmd,file=file_tasks,append=TRUE)

}
