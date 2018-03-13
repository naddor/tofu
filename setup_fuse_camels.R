rm(list=ls())

require(RColorBrewer)

### IDENTIFY COMPUTER AND SET WORKING DIRECTORIES
hostname<-system('hostname',intern=TRUE)

if(hostname=='hydro-c1'){

  source('/home/naddor/scripts/r_scripts/tofu/set_default_paths.R')
  source('/home/naddor/scripts/r_scripts/tofu/set_camels_paths.R')
  load_camels_data('2.0') # load CAMELS attributes

} else {

  stop('You are not running this script from your usual computer')

}

# set directories for FUSE files
dir_fuse_input_ch<-paste0('/glade/scratch/naddor/fusex/',country,'/input/')
dir_fuse_output_ch<-paste0('/glade/scratch/naddor/fusex/',country,'/output/')
dir_fuse_settings_ch<-paste0('/glade/scratch/naddor/fusex/',country,'/settings/')

# load functions
source(paste(dir_r_scripts,'tofu/create_forcing_nc.R',sep=''))
source(paste(dir_r_scripts,'tofu/create_elev_bands_nc.R',sep=''))
source(paste(dir_r_scripts,'tofu/create_settings.R',sep=''))
source(paste(dir_r_scripts,'read_catchment_data.R',sep='')) # move this file to CAMELS repo?

### FORCING PERIOD TO EXTRACT
date_start_forcing='19801001'
date_end_forcing='20140930'

### WARM-UP AND CALIBRATION PERIOD - BENCHMARK STUDY
date_start_sim='19900101'
date_end_spinup='19990930'
date_end_sim='20080930'

### CREATE INPUT AND SETTING FILES FOR ALL CATCHMENTS
for(i in 1:dim(camels_name)[1]){

  id=camels_name$gauge_id[i]
  huc=camels_name$huc_02[i]

  print(paste(i,'-',camels_name$gauge_name[i]))

  ### CREATE INPUT
  dat<-create_fuse_input_files(id,huc,country='us',
                              gauge_lat=camels_topo$gauge_lat[i],gauge_lon=camels_topo$gauge_lat[i],
                              date_start_forcing,date_end_forcing,
                              date_start_sim,date_end_spinup,date_end_sim,
                              return_hs_ci=FALSE,
                              return_frac_avail_qobs=TRUE,breaks_hydro_years=breaks_hydro_years,
                              list_fuse_id=list_fuse_id)
  # ELEV BANDS
  create_elevation_bands()

  # SETTINGS
  file_input_info<-paste(dir_settings,country,'_',id,'_input_info.txt',sep='')
  write_fuse_input_info(file_input_info,nc_input_file=name_forcing_file,i_start_sim,i_end_spinup,i_end_sim,
                        longrun_beg=i_start_longrun,longrun_end=i_end_longrun,numtim_sub)

  for(fuse_id in list_fuse_id){

    file_file_manager<-paste(dir_settings,country,'_',id,'_',fuse_id,'_fuse_file_manager.txt',sep='')
    write_fuse_file_manager(file_file_manager,dir_fuse_input_ch,dir_fuse_output_ch,dir_fuse_settings_ch,fuse_id=fuse_id)

  }

}

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
