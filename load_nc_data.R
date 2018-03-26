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

read_nc_output<-function(path_to_nc_file){

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

  # extract variables and store them in global environment
  qobs<<-ncvar_get(nc_id,'obsq')
  qsim<<-ncvar_get(nc_id,'q_routed')
  swe<<-ncvar_get(nc_id,'swe_tot')

  nc_close(nc_id)

}
