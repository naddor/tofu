rm(list=ls())

library(ncdf4)
library(metR)
library(data.table)

# dir_r_scripts<-'~/scripts/r_scripts/'
source(paste0(dir_r_scripts,'tofu/input_output_settings/create_forcing_nc.R'))

# load forcing, including PET
start_year<-1990
end_year<-2009
load(paste0('/gpfs/ts0/projects/Research_Project-CLES-00008/conus/indices/clim_indices_maurer_',start_year,'-',end_year,'.Rdata'))

# get dimensions
days<-as.Date(unique(dt$time))
lat<-unique(dt$latitude)
lon<-unique(dt$longitude)

if(any(diff(days)!=1)){stop('Days are missing')}

# save forcing as NetCDF files
dir_input<-'/gpfs/ts0/projects/Research_Project-CLES-00008/conus/fuse_conus/input/'
name_forcing_file<-paste0('fuse_input_maurer_',start_year,'_',end_year,'.nc')

write_input_file_nc(temp=dt$tas,prec=dt$pr,pet=dt$pet,t_input=days,
         temp_ref='Maurer',prec_ref='Maurer',pet_ref='Oudin based on Maurer',
         lat=lat,lon=lon,
         na_value=-9999,include_qobs=FALSE,grid_mode=TRUE,
         dir_input=dir_input,name_forcing_file=name_forcing_file)

# get elevation bands
file_elev<-'/gpfs/ts0/projects/Research_Project-CLES-00008/conus/elevation_bands/elevation_bands_conus_12km.nc'
GlanceNetCDF(file_elev)
mean_elev<-ReadNetCDF(file_elev,vars='mean_elev')
lat_elev<-unique(mean_elev$latitude)
lon_elev<-unique(mean_elev$longitude)

# check Maurer and elev grids are the same
all(lat_elev==lat)
all(lon_elev==lon)
