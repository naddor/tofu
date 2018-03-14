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
