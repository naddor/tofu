### EXTRACT AND WRITE ELEVATION BANDS
name_elev_bands_file<-paste(country,'_',id,'_elev_bands.nc',sep='')
elev_bands_file<-paste(dir_input,name_elev_bands_file,sep='')

if(country=='us'){

  elev_tab_format<-extract_elev_bands(id=id,huc=huc,keep_absolute_area=TRUE)
  mean_elev=sum(elev_tab_format$mid_point_elevation*elev_tab_format$area_fraction) # not quite right, because uses mid_point_elevation

}else if(country=='uk'){

  elev_tab_format<-read.table(paste0('/Volumes/d1/naddor/hc1_root/d7/naddor/fusex_original_files/uk/',id,'_elev_bands.txt'),skip=3,header=FALSE)
  names(elev_tab_format)<-c('elev_band','mid_point_elevation','area_fraction')

}else if(country=='es'){

  elev_tab_format<-read.table(paste0('/Volumes/d1/naddor/hc1_root/d7/naddor/fusex_original_files/es/',id,'_elev_bands.txt'),skip=3,header=FALSE)
  names(elev_tab_format)<-c('elev_band','mid_point_elevation','area_fraction')

}

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
