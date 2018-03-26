rm(list=ls())

# identify computer and set directories
hostname<-system('hostname',intern=TRUE)

if(hostname=='hydro-c1'){

  source('/home/naddor/scripts/r_scripts/tofu/set_default_paths.R')
  source('/home/naddor/scripts/r_scripts/tofu/set_camels_paths.R')
  load_camels_data('2.0') # load CAMELS attributes

} else {

  stop('You are not running this script from hydro!')

}

# set directories for FUSE files
dir_fuse_bin<-'/home/naddor/fuse/bin/'
dir_fuse_bin_ch<-'/glade/u/home/naddor/fuse/bin/'
dir_fuse_files<-'/d7/naddor/fuse/param_transfer_maurer/'
dir_input<-paste0(dir_fuse_files,'input/'); if(!dir.exists(dir_input)){dir.create(dir_input)}
dir_output<-paste0(dir_fuse_files,'output/'); if(!dir.exists(dir_output)){dir.create(dir_output)}
dir_settings<-paste0(dir_fuse_files,'settings/'); if(!dir.exists(dir_settings)){dir.create(dir_settings)}

# load functions
source(paste(dir_r_scripts,'tofu/create_forcing_nc.R',sep=''))
source(paste(dir_r_scripts,'tofu/create_elev_bands_nc.R',sep=''))
source(paste(dir_r_scripts,'tofu/create_settings.R',sep=''))
source(paste(dir_r_scripts,'camels/read_camels_hydromet.R',sep=''))
source(paste(dir_r_scripts,'fusex/write_qsub.R',sep=''))

# load ET functions
dir_my_functions<-paste0(dir_r_scripts,'my_functions/') # needed in my_functions_pot_evap
source(paste(dir_r_scripts,'my_functions/my_functions_pot_evap.R',sep=''))

# FUSE setup
country<-'us'
fuse_id<-902 # VIC WITH SNOW

# define period for which to extract forcing
date_start_forcing<-'19800101'
date_end_forcing<-'20081231'   # end of Maurer time series for CAMELS basins
forcing_dataset<-'maurer'
forcing_ref<-'Maurer et al., 2002'
q_obs_ref<-'HCDN-2009, Lins, 2012'
pet_ref<-'Priestly and Taylor, 1972; Newman et al., 2015'

# define period for the hydrological simulations
# Andy: "The calibration period was WY2000-2008 and validation was WY1990-1999.
# For calibration,we started the model 1 January 1990 and let it spin up for 10 years.
# For validation, we started the model at 1 January 1980 and let it spin up for 10 years."

for (exp_name in c('cal','val','all')){

  if(exp_name=='cal'){

    # Calibration benchmark study
    date_start_sim<-'1990-01-01'
    date_end_sim<-'2008-09-30'
    date_start_eval<-'1999-10-01'
    date_end_eval<-'2008-09-30'   # same as date_end_sim

  }else if(exp_name=='val'){

    # Evaluation benchmark study
    date_start_sim<-'1980-01-01'
    date_end_sim<-'1999-09-30'
    date_start_eval<-'1989-10-01'
    date_end_eval<-'1999-09-30'   # same as date_end_sim

  }else{

    date_start_sim<-'1980-01-01'
    date_end_sim<-'2008-12-31'
    date_start_eval<-'1985-10-01'
    date_end_eval<-'2008-12-31'   # same as date_end_sim

  }

  # create file manager files
  name_file_manager<-paste0('fm_',fuse_id,'_',forcing_dataset,'_benchmark_',exp_name,'.txt')
  path_file_manager<-paste0(dir_fuse_bin,name_file_manager)

  write_file_manager(path_file_manager,dir_input,dir_output,dir_settings,fuse_id,
                     date_start_sim,date_end_sim,date_start_eval,date_end_eval)

}

# loop through CAMELS catchments
for(i in 1:dim(camels_name)[1]){

  id<-camels_name$gauge_id[i]
  huc<-camels_name$huc_02[i]

  print(paste(i,'-',camels_name$gauge_name[i]))

  # retrieve hydrometeorological time series for desired data set
  input_table<-get_catchment_data_dataframe(huc,id,date_start_forcing,date_end_forcing,forcing_dataset)
  t_input<-as.Date(input_table$date,format='%Y%m%d')
  prec<-input_table$prec
  temp<-(input_table$temp_min+input_table$temp_max)/2
  q_obs<-input_table$q_obs
  pet<-input_table$pet

  # compute PET using Oudin
  # pet_o_harm<-pet_oudin(temp=temp,d=t_input,lat=gauge_lat,'harm')
  # pet_o_mov_window<-pet_oudin(temp=temp,d=t_input,lat=gauge_lat,'mov_window')

  # save forcing to NetCDF file
  name_input_file<-paste(country,'_',id,'_',forcing_dataset,'_input.nc',sep='')

  write_input_file_nc(temp,prec,pet,q_obs,t_input,
                      temp_ref=forcing_ref,prec_ref=forcing_ref,pet_ref,q_obs_ref,
                      lat=camels_topo$gauge_lat[i],lon=camels_topo$gauge_lon[i],
                      na_value=-9999,
                      dir_input,name_input_file)

  name_input_info_file<-paste(country,'_',id,'_input_info.txt',sep='') # naming structure hard-coded in FUSE

  write_input_info(paste0(dir_settings,name_input_info_file),nc_input_file=name_input_file)

  # ELEV BANDS
  elev_tab_format<-extract_camels_elev_bands(id,huc,FALSE)

  name_elev_file<-paste(country,'_',id,'_elev_bands.nc',sep='')

  write_elev_bands_nc(elev_tab_format,lat=camels_topo$gauge_lat[i],lon=camels_topo$gauge_lon[i],
                      dir_input,name_elev_file)

}

### CREATE JOB FILE

set.seed(42)
#id_us<-camels_clim$gauge_id[(order(camels_clim$frac_snow,decreasing=TRUE))[1:(3*36)]] # catchments with greatest snow fraction
n_nodes<-3
id_us<-camels_clim$gauge_id[sample(1:length(camels_clim$gauge_id),n_nodes*36)]

qsub_dir<-'/home/naddor/qsub_cheyenne/param_transfer_maurer/'

name_batch_file_def<-paste0(qsub_dir,'def/param_transfer_maurer_def.txt')
name_qsub_file_def<-paste0(qsub_dir,'def/param_transfer_maurer_def.bsh')

name_batch_file_sce<-paste0(qsub_dir,'sce/param_transfer_maurer_sce.txt')
name_qsub_file_sce<-paste0(qsub_dir,'sce/param_transfer_maurer_sce.bsh')

name_batch_file_best<-paste0(qsub_dir,'best/param_transfer_maurer_best.txt')
name_qsub_file_best<-paste0(qsub_dir,'best/param_transfer_maurer_best.bsh')

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

write_qsub(name_qsub_file_def,name_batch_file_def,batch_name='fp_def',n_nodes)
write_qsub(name_qsub_file_sce,name_batch_file_sce,batch_name='fp_sce',n_nodes)
write_qsub(name_qsub_file_best,name_batch_file_best,batch_name='fp_best',n_nodes)
