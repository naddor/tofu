extract_camels_elev_bands<-function(id,huc,keep_absolute_area=FALSE){

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
    stop('Unexpected number of elevation bands')
  }

  # compute total area as the sum of the elevation bands
  total_area_elev_bands<-sum(as.numeric(elev_tab[,2])) # in m^2

  area_geospa<-camels_topo$area_geospa_fabric[camels_name$gauge_id==id]
  rel_error_geospa<-(total_area_elev_bands*1E-6/area_geospa)-1

  if(abs(rel_error_geospa)>0.01){
    stop('Total area elevation zones does not match Geospatial Fabric area')
  }

  # create table in FUSE format
  elev_tab_format<-data.frame(array(dim=c(n_elevation_zones,4)))
  colnames(elev_tab_format)<-c('indice_elevation_zone','mid_point_elevation','area_fraction','area_m2') # add column names

  for(z in 1:n_elevation_zones){
    elev_tab_format$indice_elevation_zone[z]<-z       # first colum: indice of elevation zone
    elev_code<-as.numeric(elev_num<-strsplit(as.character(elev_tab[z,1]),'_')[[1]][4]) # 000: 0-100m, 001:100-200m, etc...
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

  # estimate mean elevation
  est_mean_elev=sum(elev_tab_format$mid_point_elevation*elev_tab_format$area_fraction) # not accurate, assumes uniform distribution within each elevation band
  mean_elev_camels<-camels_topo$elev_mean[camels_name$gauge_id==id]

  abs_error_elev<-est_mean_elev-mean_elev_camels

  if(abs(abs_error_elev)>100){
    #stop('Significant difference between catchment mean elevation estimates')
  }

  if(any(diff(elev_tab_format[,2])!=100)){
    stop('Unexpected elevation difference between two successive elevation bands')
  }

  if(abs(sum(elev_tab_format$area_fraction)-1)>1E-6){
    stop('Fraction area of elevation bands do not add up to 1')
  }

  return(elev_tab_format)

}

write_elev_bands_nc<-function(elev_tab_format,lat,lon,
                              dir_input,name_elev_file){

  # test elevation table
  if(dim(elev_tab_format)[2]!=3){
    stop('elev_tab_format must have exactly three columns: indice_elevation_zone mid_point_elevation area_fraction')
  }

  if(any(colnames(elev_tab_format)!=c("indice_elevation_zone","mid_point_elevation","area_fraction"))){
    stop('elev_tab_format columns must be named: indice_elevation_zone mid_point_elevation area_fraction')
  }

  if(abs(sum(elev_tab_format$area_fraction)-1)>1E-6){
    stop('Fraction area of elevation bands do not add up to 1')
  }

  # define NetCDF file structure
  n_elevation_zones<-dim(elev_tab_format)[1]
  dim_elev_bands<-ncdim_def( "elevation_band", "-", 1:n_elevation_zones)
  dim_lon<-ncdim_def("longitude","degreesE",lon)
  dim_lat<-ncdim_def("latitude","degreesN",lat)

  area_frac_nc<-ncvar_def('area_frac','-',dim=list(dim_lon,dim_lat,dim_elev_bands),missval = -9999,
                          longname='Fraction of the catchment covered by each elevation band')
  mean_elev_nc<-ncvar_def('mean_elev','m asl',dim=list(dim_lon,dim_lat,dim_elev_bands),missval = -9999,
                          longname='Mid-point elevation of each elevation band')
  prec_frac_nc<-ncvar_def('prec_frac','-',dim=list(dim_lon,dim_lat,dim_elev_bands),missval = -9999,
                          longname='Fraction of catchment precipitation that falls on each elevation band - same as area_frac')

  # write to NetCDF file
  elev_file_nc<-paste0(dir_input,name_elev_file)

  nc_conn<-nc_create(elev_file_nc,list(area_frac_nc,mean_elev_nc,prec_frac_nc))
  ncvar_put(nc_conn,area_frac_nc,vals=elev_tab_format$area_fraction)
  ncvar_put(nc_conn,mean_elev_nc,vals=elev_tab_format$mid_point_elevation)
  ncvar_put(nc_conn,prec_frac_nc,vals=elev_tab_format$area_fraction)
  nc_close(nc_conn)

}
