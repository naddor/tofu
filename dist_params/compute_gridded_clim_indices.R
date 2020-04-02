rm(list=ls())

library(ncdf4)
library(metR)
library(data.table)
library(ggplot2)
library(gridExtra) # for grid.arrange
library(udunits2)

dir_r_scripts<-'~/scripts/r_scripts/'

source(paste0(dir_r_scripts,'camels/clim/clim_indices.R'))
source(paste0(dir_r_scripts,'/tools/my_functions_pot_evap.R'))

dir_maurer<-'/gpfs/ts0/projects/Research_Project-CLES-00008/conus/Maurer_met_full/'

# function loading temperature and preciptiation data from NetCDF files
get_tas_pr<-function(x){

  dt_pr<-ReadNetCDF(paste0(dir_maurer,'pr/nldas_met_update.obs.daily.pr.',x,'.nc'),vars='pr')

  # assume temp data on extact same grid
  dt_pr[, tas := ReadNetCDF(paste0(dir_maurer,'tas/nldas_met_update.obs.daily.tas.',x,'.nc'),vars='tas',out = "vector")]

  # cautious (and slow) alternative
  #dt_tas<-ReadNetCDF(paste0(dir_maurer,'tas/nldas_met_update.obs.daily.tas.',x,'.nc'),vars='tas')
  #dt_pr[dt_tas, on=.(latitude,longitude,time), tas:=tas] # merge using lat/lon/time as key

  setcolorder(dt_pr, c("longitude", "latitude", "time","pr","tas")) # reorder columns

  print(paste('Data for',x,'loaded'))

  return(dt_pr)

}

# Load Maurer data over used to compute CAMELS indices - 1 October 1989 to 30 September 2009.

start_year<-1990
end_year<-1990
list_dt<-lapply(start_year:end_year,get_tas_pr)
dt<-rbindlist(list_dt)
rm(list_dt)

# check time and copy lat
if(any(diff(unique(dt$time))!=1)){stop('Days are missing')}
dt[,lat:=latitude,] # copy lat to use in PET computation

# use data.table estimate PET using Oudin et al. (2005) for each grid cell
# should use the same approach as for CAMELS to compare attributes
dt[!is.na(tas),pet:=pet_oudin(tas,time,lat,aver_method='mov_window'),by=.(latitude,longitude)]

save(file=paste0('/gpfs/ts0/projects/Research_Project-CLES-00008/conus/indices/clim_indices_maurer_',start_year,'-',end_year,'_dt_only.Rdata'),dt)

# compute climate indices for each grid cell
clim_indices<-dt[!is.na(tas),compute_climate_indices_berghuijs(tas,pr,pet,time,0.05),by=.(latitude,longitude)]

save(file=paste0('/gpfs/ts0/projects/Research_Project-CLES-00008/conus/indices/clim_indices_maurer_',start_year,'-',end_year,'_indices_only.Rdata'),clim_indices)

save.image(paste0('/gpfs/ts0/projects/Research_Project-CLES-00008/conus/indices/clim_indices_maurer_',start_year,'-',end_year,'.Rdata'))

# plot maps for three indices
my_cols <- scale_color_distiller(palette='PRGn',direction=-1) # distiller scales extend brewer to continuous scales by smoothly interpolating 7 colours from any palette to a continuous scale.
my_fill <- scale_fill_distiller(palette='PRGn',direction=-1)
usa <- map_data("usa")

#unprojected square plot-  https://stackoverflow.com/questions/43612903/how-to-properly-plot-projected-gridded-data-in-ggplot2
p_aridity<-ggplot(clim_indices, aes(y=latitude, x=longitude, fill=aridity)) +
  geom_tile() + theme_bw() + scale_fill_fermenter(palette='BrBG',breaks=c(0.5,0.75,1,1.5,2)) +
  geom_polygon(data = usa, aes(x=long, y = lat, group = group), fill = NA, color = "black")  +
  coord_fixed(1.3)

p_snow<-ggplot(clim_indices, aes(y=latitude, x=longitude, fill=frac_snow_daily)) +
  geom_tile() + theme_bw() + scale_fill_distiller(palette='Blues',direction=1) +
  geom_polygon(data = usa, aes(x=long, y = lat, group = group), fill = NA, color = "black")   +
  coord_fixed(1.3)

p_season<-ggplot(clim_indices, aes(y=latitude, x=longitude, fill=p_seasonality)) +
  geom_tile() + theme_bw() + scale_fill_distiller(palette='PiYG',direction=1) +
  geom_polygon(data = usa, aes(x=long, y = lat, group = group), fill = NA, color = "black")   +
  coord_fixed(1.3)

grid.arrange(p_season, p_aridity, p_snow, nrow = 2)

ggsave(paste0(dir_plots,'fuse_gmd/clim_indices_',start_year,'-',end_year,'.pdf'),grid.arrange(p_season, p_aridity, p_snow, nrow = 2))

# simple tests using data.table
tdt<-data.table(lon=c(10,10,11,11),lat=c(45,45,46,46),tas=c(10,11,12,11),pr=c(0,1,2,0),time=c(1,2,1,2))
tdt[,mean_tas:=mean(tas),lat]
tdt[,pet:=rev(tas),lat]

tf<-function(x){data.frame(sum=sum(x),mean=mean(x))}
tdt[,c('mean2','sum2'):=tf(tas)[c('mean','sum')],lat]
tdt[,tf(tas),.(lat,lon)]
