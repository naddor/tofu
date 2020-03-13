require(ncdf4)

read_nc_input<-function(path_to_nc_file){

  # open file
  nc_id<-nc_open(path_to_nc_file)

  # get time
  d_raw<-ncvar_get(nc_id,'time')
  d_unit <-ncatt_get(nc_id,'time')$units
  d_unit_split<-strsplit(d_unit,' ')[[1]]

  if(paste(d_unit_split[1:2],collapse =' ')!='days since'|any(diff(d_raw)!=1)){ # check that we're dealing with daily values

   stop('Unexpected time format.')

  }

  d_origin<-as.Date(d_unit_split[3],'%Y-%m-%d')
  d_input<<-d_origin+d_raw

  # extract variables and store them in global environment
  pr<<-ncvar_get(nc_id,'pr')
  pet<<-ncvar_get(nc_id,'pet')
  temp<<-ncvar_get(nc_id,'temp')
  q_obs<<-ncvar_get(nc_id,'q_obs')

  nc_close(nc_id)

}

read_nc_output<-function(path_to_nc_file,var_to_extract=c('q_obs','q_routed')){

  # options for var_to_extract: 'qobs','qsim','q_instant','swe'
  # date extracted and saved as global variable regardless

  if(any(!var_to_extract%in%c('q_obs','q_routed','q_instant','swe'))){

    stop('Variables to extract can only be: q_obs, q_routed, q_instant, swe')

  }

  # open file
  nc_id<-nc_open(path_to_nc_file)

  # get time
  d_raw<-ncvar_get(nc_id,'time')
  d_unit <-ncatt_get(nc_id,'time')$units
  d_unit_split<-strsplit(d_unit,' ')[[1]]

  if(paste(d_unit_split[1:2],collapse =' ')!='days since'|any(diff(d_raw)!=1)){ # check that we're dealing with daily values

   stop('Unexpected time format.')

  }

  d_origin<-as.Date(d_unit_split[3],'%Y-%m-%d')
  d_output<<-d_origin+d_raw

  # extract required variables and store them in global environment
  # variables not required are overwritten and set to NA
  if('q_obs'%in%var_to_extract){q_obs<<-ncvar_get(nc_id,'obsq')}else{qobs<<-NA}
  if('q_routed'%in%var_to_extract){q_routed<<-ncvar_get(nc_id,'q_routed')}else{qsim<<-NA}
  if('q_instant'%in%var_to_extract){q_instant<<-ncvar_get(nc_id,'q_instnt')}else{q_instant<<-NA}
  if('swe'%in%var_to_extract){swe<<-ncvar_get(nc_id,'swe_tot')}else{swe<<-NA}

  nc_close(nc_id)

}
