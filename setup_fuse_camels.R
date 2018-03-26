rm(list=ls())

# identify computer and set directories
hostname<-system('hostname',intern=TRUE)

if(hostname=='hydro-c1'){

  source('/home/naddor/scripts/r_scripts/tofu/set_default_paths.R')
  source('/home/naddor/scripts/r_scripts/tofu/set_camels_paths.R')
  load_camels_data('2.0') # load CAMELS attributes

} else {

  stop('This script must run on hydro, where the CAMELS time series are located')

}

# FUSE setup
country<-'us'
fuse_id<-902 # VIC WITH SNOW

# define period for which to extract forcing
date_start_forcing<-'19800101'
date_end_forcing<-'20081231'   # end of Maurer time series for CAMELS basins
forcing_dataset<-'maurer'
forcing_ref<-'Maurer et al., 2002'
q_obs_ref<-'HCDN-2009, Lins, 2012'

# set directories for FUSE files
dir_fuse_bin<-'/home/naddor/fuse/bin/'
dir_fuse_files<-paste0('/d7/naddor/fuse/param_transfer_',forcing_dataset,'/')
dir_input<-paste0(dir_fuse_files,'input/'); if(!dir.exists(dir_input)){dir.create(dir_input)}
dir_output<-paste0(dir_fuse_files,'output_',fuse_id,'/'); if(!dir.exists(dir_output)){dir.create(dir_output)}
dir_settings<-paste0(dir_fuse_files,'settings/'); if(!dir.exists(dir_settings)){dir.create(dir_settings)}

# load functions
source(paste(dir_r_scripts,'tofu/create_forcing_nc.R',sep=''))
source(paste(dir_r_scripts,'tofu/create_elev_bands_nc.R',sep=''))
source(paste(dir_r_scripts,'camels/read_camels_hydromet.R',sep=''))

# load ET functions
dir_my_functions<-paste0(dir_r_scripts,'my_functions/') # needed in my_functions_pot_evap
source(paste(dir_r_scripts,'my_functions/my_functions_pot_evap.R',sep=''))

# loop through CAMELS catchments
for(i in 1:dim(camels_name)[1]){

  id<-camels_name$gauge_id[i]
  huc<-camels_name$huc_02[i]
  gauge_lat<-camels_topo$gauge_lat[i]

  print(paste(i,'-',camels_name$gauge_name[i]))

  # retrieve hydrometeorological time series for desired data set
  input_table<-get_catchment_data_dataframe(huc,id,date_start_forcing,date_end_forcing,forcing_dataset)
  t_input<-as.Date(input_table$date,format='%Y%m%d')
  prec<-input_table$prec
  temp<-(input_table$temp_min+input_table$temp_max)/2
  q_obs<-input_table$q_obs
  #pet<-input_table$pet

  # compute PET using Oudin
  pet_ref<-'Oudin et al., 2005' # for NetCDF metadata
  pet<-pet_oudin(temp=temp,d=t_input,lat=gauge_lat,'harm')
  pet_mov<-pet_oudin(temp=temp,d=t_input,lat=gauge_lat,'mov_window')

  #plot(t_input[1:1000],pet[1:1000],type='l')
  #lines(t_input[1:1000],pet_mov[1:1000],type='l',col='orange')

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
