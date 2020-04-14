rm(list=ls())

library(ncdf4)

source(paste0(dir_r_scripts,'tofu/input_output_settings/create_elev_bands_nc.R'))

dir_input<-'/gpfs/ts0/projects/Research_Project-CLES-00008/conus/fuse_conus/input/'
file_input<-'maurer_1990_input.nc'
file_elev<-'maurer_elev_bands_including_columbia.nc'

# get lat/lon input
nc_id<-nc_open(paste0(dir_input,file_input))
lat_input<-ncvar_get(nc_id,'latitude')
lon_input<-ncvar_get(nc_id,'longitude')
dat_input<-ncvar_get(nc_id,'temp')[,,1]
nc_close(nc_id)

# get lat/lon elev
nc_id<-nc_open(paste0(dir_input,file_elev))
lat_elev<-ncvar_get(nc_id,'latitude')
lon_elev<-ncvar_get(nc_id,'longitude')
dat_elev<-ncvar_get(nc_id,'mean_elev')[,,1]
#nc_close(nc_id)

# visual test
image(dat_input)
X11()
image(dat_elev)

# some grid cells have negative elevation (e.g. Death Valley)
image(dat_elev<0)

# check grid dimension
length(lat_input)
length(lat_elev)

length(lon_input)
length(lon_elev)

# check coordinates
any(lat_input!=lat_elev)
any(lon_input!=lon_elev)

# any places where we have forcing but not elevation bands?
image(!is.na(dat_input)&is.na(dat_elev))

# set elevations bands in these places to NA (e.g. in the Canadian part of the Columbia River basin)
area_frac<-ncvar_get(nc_id,'area_frac')
mean_elev<-ncvar_get(nc_id,'mean_elev')
prec_frac<-ncvar_get(nc_id,'prec_frac')
nc_close(nc_id)

image(is.na(area_frac)[,,1])
area_frac[is.na(dat_input)]<-NA
image(is.na(area_frac)[,,1])
image(is.na(area_frac)[,,2])
mean_elev[is.na(dat_input)]<-NA
prec_frac[is.na(dat_input)]<-NA

write_elev_bands_3d_nc(area_frac,mean_elev,prec_frac,
                       lat_elev,lon_elev,
                       dir_input,'maurer_1990_elev_bands.nc')
