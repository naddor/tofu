rm(list=ls())

library(ncdf4)
library(abind)

dir_r_scripts<-'~/scripts/r_scripts/'

source(paste0(dir_r_scripts,'camels/clim/clim_indices.R'))
source(paste0(dir_r_scripts,'/tools/my_functions_pot_evap.R'))
source(paste0(dir_r_scripts,'tofu/input_output_settings/write_forcing.R'))

dir_input<-'/gpfs/ts0/projects/Research_Project-CLES-00008/conus/Maurer_w_MX_CAN/'

# function loading temperature and precipitation data from NetCDF files
get_tas_pr<-function(x,var){

  if(var=='pr'){

    nc_id<-nc_open(paste0(dir_input,'pr/gridded_obs.daily.Prcp.',x,'.nc'))
    dat<-ncvar_get(nc_id,'Prcp')
    lat<-ncvar_get(nc_id,'latitude')
    lon<-ncvar_get(nc_id,'longitude')

  }else if(var=='tas'){

    nc_id<-nc_open(paste0(dir_input,'tasmin/gridded_obs.daily.Tmin.',x,'.nc'))
    tmin<-ncvar_get(nc_id,'Tmin')
    lat<-ncvar_get(nc_id,'latitude')
    lon<-ncvar_get(nc_id,'longitude')
    nc_close(nc_id)

    nc_id<-nc_open(paste0(dir_input,'tasmax/gridded_obs.daily.Tmax.',x,'.nc'))
    tmax<-ncvar_get(nc_id,'Tmax')
    if(any(lat!=ncvar_get(nc_id,'latitude'))){stop('Error in lat')}
    if(any(lon!=ncvar_get(nc_id,'longitude'))){stop('Error in lat')}

    # compute mean temp
    dat<-(tmin+tmax)/2

  }

  # get time
  d_raw<-ncvar_get(nc_id,'time')
  d_unit <-ncatt_get(nc_id,'time')$units
  d_unit_split<-strsplit(d_unit,' ')[[1]]

  if(paste(d_unit_split[1:2],collapse =' ')!='days since'|any(diff(d_raw)!=1)){ # check that we're dealing with daily values

   stop('Unexpected time format.')

  }

  d_origin<-as.Date(d_unit_split[3],'%Y-%m-%d')
  d_input<-d_origin+d_raw

  nc_close(nc_id)

  print(paste('Data for',x,'loaded'))

  return(list(dat,d_input,lat,lon))

}

# load data
start_year<-1975
end_year<-1999

dat_list<-lapply(start_year:end_year,get_tas_pr,'pr')
pr<-do.call(abind,lapply(dat_list,function(x)x[[1]]))
rm(dat_list)

dat_list<-lapply(start_year:end_year,get_tas_pr,'tas')
tas<-do.call(abind,lapply(dat_list,function(x)x[[1]]))
d_input<-do.call(c,lapply(dat_list,function(x)x[[2]]))
lat<-unlist(dat_list[[1]][3])
lon<-unlist(dat_list[[1]][4])
rm(dat_list)

if(any(diff(d_input)!=1)){stop('Days are missing')}

# estimate PET
pet<-tas*NA

for(i in 1:dim(tas)[1]){

  for(j in 1:dim(tas)[2]){

    print(paste(i,j))

    if(!any(is.na(tas[i,j,]))){
      pet[i,j,]<-pet_oudin(tas[i,j,],d_input,lat,aver_method='mov_window')
    }
  }
}

# Maurer_CA_MX forcing only - fill in gaps in 8 grid cells needed to run MizuRoute
# (mostly in California), using the average of the eight neighbor cells.

# indices of missing grid cells
miss_row<-c(69,52,53,55,33,35,74,76)
miss_col<-c(64,73,73,73,80,80,81,81)

# visual check
image(tas[,,1])

# size of the window to consider around missing cell
w<-(-1:1)

#zonal_mean<-function(mat){return(mean(mat[mat!=-9999]))}

for (m in 1:length(miss_row)){ # loop through grid cells with missing values

  print(pet[miss_row[m]+w,miss_col[m]+w,1]) # before: show values around missing cell

  pet[miss_row[m],miss_col[m],]<-apply(pet[miss_row[m]+w,miss_col[m]+w,],3,mean,na.rm=TRUE)
  tas[miss_row[m],miss_col[m],]<-apply(tas[miss_row[m]+w,miss_col[m]+w,],3,mean,na.rm=TRUE)
  pr[miss_row[m],miss_col[m],]<-apply(pr[miss_row[m]+w,miss_col[m]+w,],3,mean,na.rm=TRUE)

  print(pet[miss_row[m]+w,miss_col[m]+w,1]) # after: show values around missing cell

}

# visual check
image(tas[,,1])

## write to disk
write_input_file_nc(tas,pr,pet,d_input,q_obs=NA,
                    'Maurer_CA_MX - http://hydro.engr.scu.edu/files/gridded_obs/daily/ncfiles/','Maurer_MX_CA - http://hydro.engr.scu.edu/files/gridded_obs/daily/ncfiles/','Oudin et al. (2005) based on Maurer_CA_MX',q_obs_ref=NA,
                    lat,lon,
                    na_value=-9999,include_qobs=FALSE,grid_mode=TRUE,
                    paste0(dir_input,'all/'),paste0('conus_ca_mx_',start_year,'_',end_year,'.nc'))
