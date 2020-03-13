rm(list=ls())

dir_output<-'/d7/naddor/fuse/param_transfer/output/'
#file_list<-'/home/naddor/fuse/bin/list_param_all.txt'

files_para_best<-system(paste0('ls ',dir_output,'*para_best*'),intern=TRUE)

#if(file.exists(file_list)){file.remove(file_list)}

for (p in 1:length(files_para_best)){

  file_split<-strsplit(files_para_best[p],'/')[[1]]
  file_name<-file_split[length(file_split)]
  station_id<-strsplit(file_name,'_')[[1]][2]

  # skip basins with corrupted NetCDF files
  if(!station_id%in%c('02235200','04115265','04074950','09378170','10310500','12143600','12381400','12388400')){

    write(file_name,file=file_list,append=TRUE)

  }
}

### CREATE LIST OF CATCHMENTS TO run_def

run_id<-array()
counter_catch=1

for (p in 1:length(files_para_best)){

  file_split<-strsplit(files_para_best[p],'/')[[1]]
  file_name<-file_split[length(file_split)]
  station_id<-strsplit(file_name,'_')[[1]][2]

  if(!station_id%in%c('02235200','04115265','04074950','09378170','10310500','12143600','12381400','12388400')){

    run_id[counter_catch]<-station_id
    counter_catch=counter_catch+1

  }
}

paste0(run_id[32+(1:64)],collapse='" "')   # batch 2 - node 6
paste0(run_id[3*32+(1:96)],collapse='" "') # batch 3 - node 6
paste0(run_id[6*32+(1:96)],collapse='" "') # batch 4 - node 7
paste0(run_id[9*32+(1:(6*32))],collapse='" "') # batch 5 - node 6
paste0(run_id[((15*32)+1):length(run_id)],collapse='" "') # batch 6 - node 7
