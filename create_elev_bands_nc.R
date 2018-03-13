extract_elev_bands<-function(id,huc,keep_absolute_area=FALSE){

  # locate file in which elevations bands are stored
  file_elev<-paste(dir_basin_dataset,'elev_bands_forcing/daymet/',huc,'/',id,'.list',sep='')
  n_elevation_zones<-as.numeric(read.table(file_elev,header=FALSE,nrows=1)) # get number of elevation zones from first line
  elev_tab<-read.table(file_elev,skip=1,header=FALSE)

  # some elevations bands have negative area - this is a a bug
  if(any(elev_tab[,2]<0)){
    elev_tab[,2]<-abs(elev_tab[,2]) # remove eventual minus signs
  }

  # check number of elevation bands - consistency check
  if(dim(elev_tab)[1]!=n_elevation_zones){
    stop('Problem with the number of elevation bands')
  }

  # compute total area as the sum of the elevation bands
  total_area_elev_bands<-sum(as.numeric(elev_tab[,2])) # in m^2

  # create table in FUSE format
  elev_tab_format<-data.frame(array(dim=c(n_elevation_zones,4)))

  colnames(elev_tab_format)<-c('indice_elevation_zone','mid_point_elevation','area_fraction','area_m2')

  for(z in 1:n_elevation_zones){
    elev_tab_format$indice_elevation_zone[z]<-z       # first colum: indice of elevation zone
    elev_code<-as.numeric(elev_num<-strsplit(as.character(elev_tab[z,1]),'_')[[1]][4])
    elev_tab_format$mid_point_elevation[z]<-elev_code*100+50 # second colum: mid-point elevation
    elev_tab_format$area_fraction[z]<-elev_tab[z,2]/total_area_elev_bands # third column: fraction of the area in this elevation band
    elev_tab_format$area_m2[z]<-elev_tab[z,2]  # fourth column: area in this elevation band - not needed by FUSE, only for verification purposes
  }

  if(!keep_absolute_area){
    elev_tab_format<-elev_tab_format[,-4]
  }

  # sort rows by mean elevation
  if(n_elevation_zones>1){
    elev_tab_format<-elev_tab_format[order(elev_tab_format[,2]),]
    elev_tab_format[,1]<-1:n_elevation_zones
  }

  if(any(diff(elev_tab_format[,2])!=100)){
    stop('Unexpected distance between two successive elevation bands')
  }

  return(elev_tab_format)

}

write_elev_bands<-function(id,huc,keep_absolute_area=TRUE){

  ### EXTRACT AND WRITE ELEVATION BANDS
  name_elev_bands_file<-paste(country,'_',id,'_elev_bands.nc',sep='')
  elev_bands_file<-paste(dir_input,name_elev_bands_file,sep='')

  elev_tab_format<-extract_elev_bands(id=id,huc=huc,keep_absolute_area=keep_absolute_area)
  mean_elev=sum(elev_tab_format$mid_point_elevation*elev_tab_format$area_fraction) # not quite right, because uses mid_point_elevation

  n_elevation_zones<-dim(elev_tab_format)[1]

  if(n_elevation_zones==1){
  #  write(paste(c(sprintf("%2d", elev_tab_format[1]),sprintf("%13d", elev_tab_format[2]),sprintf("%30.10f", elev_tab_format[3])),collapse = ''),
  #       file=elev_bands_file,append=TRUE)
  } else {
  #  apply(elev_tab_format[,-4],1,function(x) write(paste(c(sprintf("%2d", x[1]),sprintf("%13d", x[2]),sprintf("%30.10f", x[3])),collapse = ''),
  #                                                file=elev_bands_file,append=TRUE))
  }

  dim_elev_bands<-ncdim_def( "elevation_band", "-", 1:n_elevation_zones)

  area_frac_nc<-ncvar_def('area_frac','-',dim=list(dim_lon,dim_lat,dim_elev_bands),missval = -9999,
                          longname='Fraction of the catchment covered by each elevation band')
  mean_elev_nc<-ncvar_def('mean_elev','m asl',dim=list(dim_lon,dim_lat,dim_elev_bands),missval = -9999,
                          longname='Mid-point elevation of each elevation band')
  prec_frac_nc<-ncvar_def('prec_frac','-',dim=list(dim_lon,dim_lat,dim_elev_bands),missval = -9999,
                          longname='Fraction of catchment precipitation that falls on each elevation band - same as area_frac')

  nc_conn<-nc_create(elev_bands_file,list(area_frac_nc,mean_elev_nc,prec_frac_nc))
  ncvar_put(nc_conn,area_frac_nc,vals=elev_tab_format$area_fraction)
  ncvar_put(nc_conn,mean_elev_nc,vals=elev_tab_format$mid_point_elevation)
  ncvar_put(nc_conn,prec_frac_nc,vals=elev_tab_format$area_fraction)
  nc_close(nc_conn)

}
