require(ncdf4)

write_input_file_nc<-function(temp,prec,pet,q_obs,t_input,
                               gauge_lat=-9999,gauge_lon=-9999,
                               na_value=-9999,
                               dir_input,name_forcing_file){

  # check array length
  if(any(diff(c(length(temp),length(prec),length(pet),length(q_obs),length(t_input)))!=0)){
    stop('temp, prec, pet, q_obs and t_allyears must have the same length')
  }

  # define dimensions
  dim_lon<-ncdim_def("longitude","degreesE",gauge_lon)
  dim_lat<-ncdim_def("latitude","degreesN",gauge_lat)
  dim_time<-ncdim_def("time",paste("days since 1970-01-01"),as.numeric(t_input),unlim=TRUE)

  # define variables
  tas_nc<-ncvar_def('temp','degC',dim=list(dim_lon,dim_lat,dim_time),missval=na_value,
                 longname='Mean daily temperature')
  pr_nc<-ncvar_def('pr','mm/day',dim=list(dim_lon,dim_lat,dim_time),missval=na_value,
                longname='Mean daily precipitation')
  pet_nc<-ncvar_def('pet','mm/day',dim=list(dim_lon,dim_lat,dim_time),missval=na_value,
                longname='Potential evaportanspiration estimated using Oudin et al., 2005, JoH')
  q_obs_nc<-ncvar_def('q_obs','mm/day',dim=list(dim_lon,dim_lat,dim_time),missval=na_value,
                 longname='Mean observed daily discharge')

  # write variables to file
  input_file_nc<-paste0(dir_input,'/',name_forcing_file)

  nc_conn<-nc_create(input_file_nc,list(tas_nc,pr_nc,pet_nc,q_obs_nc))
  ncvar_put(nc_conn,tas_nc,vals=temp)
  ncvar_put(nc_conn,pr_nc,vals=prec)
  ncvar_put(nc_conn,pet_nc,vals=pet)
  ncvar_put(nc_conn,q_obs_nc,vals=q_obs)
  nc_close(nc_conn)

}

write_input_info<-function(file_name,nc_input_file){

  content<-paste('! used to define information for the forcing file
! -----------------------------------------------------------------------------------------------------------
! lines starting with exclamation marks are not read
! (variables can be in any order)
! -----------------------------------------------------------------------------------------------------------
<version>         FORCINGINFO.VERSION.2.1              ! string to ensure version of file matches the code
<forcefile>       ',nc_input_file,'! name of data file
<vname_iy>        undefined                            ! name of variable for year
<vname_im>        undefined                            ! name of variable for month
<vname_id>        undefined                            ! name of variable for day
<vname_ih>        undefined                            ! name of variable for hour
<vname_imin>      undefined                            ! name of variable for minute
<vname_dsec>      undefined                            ! name of variable for second
<vname_dtime>     time                                 ! time since reference time
<vname_aprecip>   pr                                   ! variable name: precipitation
<vname_airtemp>   temp                                 ! variable name: temperature
<vname_spechum>   undefined                            ! variable name: specific humidity
<vname_airpres>   undefined                            ! variable name: surface pressure
<vname_swdown>    undefined                            ! variable name: downward shortwave radiation
<vname_potevap>   pet                                  ! variable name: potential ET
<vname_q>         q_obs                                ! variable name: runoff
<units_aprecip>   mm/d                                 ! units: precipitation
<units_airtemp>   degC                                 ! units: temperature
<units_spechum>   undefined                            ! units: specific humidity
<units_airpres>   undefined                            ! units: surface pressure
<units_swdown>    undefined                            ! units: downward shortwave radiation
<units_potevap>   mm/d                                 ! units: potential ET
<units_q>         mm/d                                 ! units: runoff
<deltim>          1.0                                  ! time step (days)
<xlon>            -75.00                               ! longitude
<ylat>              4.00                               ! latitude',sep='')

  fileConn<-file(file_name)
  writeLines(content, fileConn)
  close(fileConn)

}
