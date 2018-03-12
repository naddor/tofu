require(ncdf4)

### IDENTIFY COMPUTER AND SET WORKING DIRECTORIES

hostname<-system('hostname',intern=TRUE)

if(hostname=='uncertainty.rap.ucar.edu'|substr(hostname,1,3)=='vpn'){

  source('/Volumes/d1/naddor/hc1_home/scripts/r_scripts/set_paths.R')

} else {

  source('/home/naddor/scripts/r_scripts/set_paths.R')

}

source(paste(dir_r_scripts,'read_catchment_data.R',sep=''))
source(paste(dir_r_scripts,'catch_clustering/extract_elev_bands.R',sep=''))
source(paste(dir_r_scripts,'fusex/create_fuse_settings.R',sep=''))

dir_my_functions<-paste0(dir_r_scripts,'my_functions/') # needed for my_functions_pot_evap
source(paste(dir_r_scripts,'my_functions/my_functions_pot_evap.R',sep=''))

create_fuse_input_files<-function(id,huc=9999,country,
                                  gauge_lat=-9999,gauge_lon=-9999,
                                  date_start_forcing='19801001',date_end_forcing='20140930',
                                  date_start_sim,date_end_spinup,date_end_sim,
                                  na_value=-9999,
                                  return_hs_ci=FALSE,
                                  return_frac_avail_qobs=FALSE,breaks_hydro_years=NA,
                                  list_fuse_id){

  # local dir
  dir_input=paste0('/d7/naddor/fusex/',country,'/input/')
  dir_settings=paste0('/d7/naddor/fusex/',country,'/settings/')

  if(date_start_sim>date_end_spinup|date_end_spinup>date_end_sim){

    stop('Check that date_start_sim < date_end_spinup < date_end_sim')

  }

  ### WRITE FORCING FILE - CONTAINS BY DEFAULT THE FORCING AND DISCHARGE FOR THE WHOLE 1980-2014 PERIOD

  if(country=='us'){

    input_table<-get_catchment_data_dataframe(huc,id,date_start_forcing,date_end_forcing)

    YYYY<-as.numeric(substr(input_table$date,1,4))
    MM<-sprintf('%02s',substr(input_table$date,5,6))
    DD<-sprintf('%02s',substr(input_table$date,7,8))
    t_allyears<-as.Date(paste0(YYYY,MM,DD),format='%Y%m%d')

    # deal with missing values in forcing data
    if(any(c(is.na(input_table$temp_min+input_table$temp_min),is.na(input_table$prec),is.na(input_table$pet)))){

      #stop('Missing values were found in the forcing data.')

    }

    prec<-input_table$prec
    temp<-(input_table$temp_min+input_table$temp_max)/2
    q_obs<-input_table$q_obs
    pet<-input_table$pet

  }

  # compute PET using Oudin
  pet_o_harm<-pet_oudin(temp=temp,d=t_allyears,lat=gauge_lat,'harm')
  pet_o_mov_window<-pet_oudin(temp=temp,d=t_allyears,lat=gauge_lat,'mov_window')

  if(any(!is.na(pet[1:1000]))){

    pdf(paste0(dir_plots,'fusex/test_pet/',country,'_',id,'_pet.pdf'))

    plot(t_allyears[1:1000],pet[1:1000],ylim=c(0,max(c(pet,pet_o_harm,pet_o_mov_window),na.rm=TRUE)))
    lines(t_allyears[1:1000],pet_o_harm[1:1000],col='darkorange2',lwd=2)
    lines(t_allyears[1:1000],pet_o_mov_window[1:1000],col='cadetblue3',lwd=2)

    if(id=='x9269'){

      lines(t_allyears[1:1000],pet_wrong[1:1000],col='red',type='p',pch=4)

    }

    dev.off()

  }

  # define period simulated
  i_start_sim<-which(format(t_allyears,'%Y%m%d')==date_start_sim)
  i_end_spinup<-which(format(t_allyears,'%Y%m%d')==date_end_spinup)
  i_end_sim<-which(format(t_allyears,'%Y%m%d')==date_end_sim)
  i_start_longrun<-1
  i_end_longrun<-length(t_allyears)

  numtim_sub<-i_end_sim-i_start_sim+1 # run whole time series at once - THIS WILL BE OVERWRITTEN

  # turn missing values to -9999
  q_obs[is.na(q_obs)]<-na_value

  # save forcing to NetCDF file
  name_forcing_file<-paste(country,'_',id,'_input.nc',sep='')
  forcing_file<-paste(dir_input,name_forcing_file,sep='')

  dim_lon<-ncdim_def("longitude","degreesE",gauge_lon)
  dim_lat<-ncdim_def("latitude","degreesN",gauge_lat)
  dim_t_allyears<-ncdim_def("time",paste("days since 1970-01-01"),as.numeric(t_allyears),unlim=TRUE)

  ### define NetCDF variables
  tas_nc<-ncvar_def('temp','degC',dim=list(dim_lon,dim_lat,dim_t_allyears),missval = -9999,
                 longname='Mean daily temperature')
  pr_nc<-ncvar_def('pr','mm/day',dim=list(dim_lon,dim_lat,dim_t_allyears),missval = -9999,
                longname='Mean daily precipitation')
  pet_nc<-ncvar_def('pet','mm/day',dim=list(dim_lon,dim_lat,dim_t_allyears),missval = -9999,
                longname='Potential evaportanspiration estimated using Oudin et al., 2005, JoH')
  q_obs_nc<-ncvar_def('q_obs','mm/day',dim=list(dim_lon,dim_lat,dim_t_allyears),missval = -9999,
                 longname='Mean observed daily discharge')

  # populate variables
  nc_conn<-nc_create(forcing_file,list(tas_nc,pr_nc,pet_nc,q_obs_nc))
  ncvar_put(nc_conn,tas_nc,vals=temp)
  ncvar_put(nc_conn,pr_nc,vals=prec)
  ncvar_put(nc_conn,pet_nc,vals=pet)
  ncvar_put(nc_conn,q_obs_nc,vals=q_obs)
  nc_close(nc_conn)

  # RETURN

  list_return<-list()

  if(return_frac_avail_qobs){

    list_return[['frac_avail_qobs']]<-frac_avail_qobs

  }

  if(return_hs_ci){

    list_return[['clim_ind']]<-clim_ind
    list_return[['hydro_sign']]<-hydro_sign

  }

  return(list_return)

}
