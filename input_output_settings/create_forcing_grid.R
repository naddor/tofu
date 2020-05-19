rm(list=ls())

library(ncdf4)
library(metR)
library(data.table)
library(ggplot2)
library(raster)
#library(udunits2)

dir_r_scripts<-'~/scripts/r_scripts/'

source(paste0(dir_r_scripts,'camels/clim/clim_indices.R'))
source(paste0(dir_r_scripts,'/tools/my_functions_pot_evap.R'))
source(paste0(dir_r_scripts,'tofu/input_output_settings/write_forcing.R'))

dir_input<-'/gpfs/ts0/projects/Research_Project-CLES-00008/conus/Maurer_w_MX_CAN/'

# function loading temperature and preciptiation data from NetCDF files
get_tas_pr<-function(x){

  dt_input<-ReadNetCDF(paste0(dir_input,'pr/gridded_obs.daily.Prcp.',x,'.nc'),vars='Prcp')

  # assume temp data on extact same grid
  dt_input[, tmin := ReadNetCDF(paste0(dir_input,'tasmin/gridded_obs.daily.Tmin.',x,'.nc'),vars='Tmin',out = "vector")]
  dt_input[, tmax := ReadNetCDF(paste0(dir_input,'tasmax/gridded_obs.daily.Tmax.',x,'.nc'),vars='Tmax',out = "vector")]
  dt_input[, tas := (tmin+tmax)/2]

  # cautious (and slow) alternative
  #dt_tas<-ReadNetCDF(paste0(dir_maurer,'tas/nldas_met_update.obs.daily.tas.',x,'.nc'),vars='tas')
  #dt_pr[dt_tas, on=.(latitude,longitude,time), tas:=tas] # merge using lat/lon/time as key

  # tidy up
  dt_input<-dt_input[,c("longitude", "latitude", "time","Prcp","tas")]
  setnames(dt_input, "Prcp", "prec")

  # quick visual test
  #m<-dt_input[!is.na(tas),mean(tas),by=.(latitude,longitude)]
  #ggplot(m, aes(longitude, latitude)) +
  #  geom_contour_fill(aes(z = V1, color = ..level..),na.fill=TRUE)

  print(paste('Data for',x,'loaded'))

  return(dt_input)

}

# load data
start_year<-1980
end_year<-1989
list_dt<-lapply(start_year:end_year,get_tas_pr)
dt_input<-rbindlist(list_dt)
rm(list_dt)

# check time and copy lat
if(any(diff(unique(dt_input$time))!=1)){stop('Days are missing')}
dt_input[,lat:=latitude,] # copy lat to use in PET computation

# use data.table estimate PET using Oudin et al. (2005) for each grid cell
dt_input[!is.na(tas),pet:=pet_oudin(tas,time,lat,aver_method='mov_window'),by=.(latitude,longitude)]

# reshape data
pet<- rasterFromXYZ(dcast(dt_input, latitude  + rev(longitude) ~ time, value.var = "pet"))
temp<- rasterFromXYZ(dcast(dt_input, latitude + rev(longitude) ~ time, value.var = "tas"))
prec<- rasterFromXYZ(dcast(dt_input, latitude + rev(longitude) ~ time, value.var = "prec"))
t_input<-as.Date(unique(dt_input$time))
lat<-unique(dt_input$latitude)
lon<-unique(dt_input$longitude)

## write to disk
write_input_file_nc(as.array(temp),as.array(prec),as.array(pet),t_input,q_obs=NA,
                    'Maurer_MX_CA','Maurer_MX_CA','Oudin based on Maurer_MX_CA',q_obs_ref=NA,
                    lat,lon,
                    na_value=-9999,include_qobs=FALSE,grid_mode=TRUE,
                    dir_input,paste0('test',start_year,'_',end_year,'.nc'))
