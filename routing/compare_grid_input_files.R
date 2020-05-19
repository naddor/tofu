rm(list=ls())

library(ncdf4)

dir_gf<-'/gpfs/ts0/projects/Research_Project-CLES-00008/mizuroute_data/GF_conus/'
dir_fuse_conus<-'/gpfs/ts0/projects/Research_Project-CLES-00008/conus/fuse_conus/'
dir_maurer_mx_ca<-'/gpfs/ts0/projects/Research_Project-CLES-00008/conus/Maurer_w_MX_CAN/'

### RUNOFF NETCDF FILES

# Maurer mizuroute
nc_id<-nc_open(paste0(dir_gf,'input/maurer02_runoff_grid12km_1950.nc'))
lat_maurer_input<-ncvar_get(nc_id,'lat')
lon_maurer_input<-ncvar_get(nc_id,'lon')
dat_maurer_input<-ncvar_get(nc_id,'RUNOFF')[,,1]
nc_close(nc_id)

# Livneh mizuroute
nc_id<-nc_open(paste0(dir_gf,'input/Livneh_L14_CONUS_12km.hist.total_runoff.1992-1993.nc'))
lat_livneh_input<-ncvar_get(nc_id,'lat')
lon_livneh_input<-ncvar_get(nc_id,'lon')
dat_livneh_input<-ncvar_get(nc_id,'total_runoff')[,,1]
nc_close(nc_id)

# FUSE Maurer mizuroute
nc_id<-nc_open(paste0(dir_fuse_conus,'output/maurer_1990_2009_900_runs_def.nc'))
lat_maurer_fuse<-ncvar_get(nc_id,'latitude')
lon_maurer_fuse<-ncvar_get(nc_id,'longitude')
dat_maurer_fuse<-ncvar_get(nc_id,'q_instnt')[,,1]
nc_close(nc_id)

# Maurer with MX and CA
nc_id<-nc_open(paste0(dir_maurer_mx_ca,'gridded_obs.daily.Prcp.1999.nc'))
lat_maurer_mx<-ncvar_get(nc_id,'latitude')
lon_maurer_mx<-ncvar_get(nc_id,'longitude')
dat_maurer_mx<-ncvar_get(nc_id,'Prcp')[,,1]
nc_close(nc_id)

# visual test
image(dat_maurer_input) # only grid cells contributing to streamflow in conus (includes canadian part of columbia basin)
X11()
image(dat_livneh_input) # includes canada and mexico grid cells not contributing to streamflow in conus
X11()
image(dat_maurer_fuse) # does not include canadian part Columbia river basin
X11()
image(dat_maurer_mx) # does include canadian part Columbia river basin

# check grid dimension -> liven 2 grid cells larger in both dimensions
length(lat_maurer_input)
length(lat_livneh_input)

length(lon_maurer_input)
length(lon_livneh_input)

# check coordinates -> all maurer grid cells are in livneh
all(lat_maurer_input%in%lat_livneh_input)
all(lon_maurer_input%in%lon_livneh_input)

# check coordinates -> grid for mizuroute maurer grid matches fuse maurer
all(lat_maurer_input==lat_maurer_fuse)
all(lon_maurer_input==lon_maurer_fuse)

all(lat_maurer_input==lat_maurer_mx)
all(lon_maurer_input==lon_maurer_mx)

### SPATIAL WEIGHTS NETCDF FILES

# get spatial weight maurer
nc_id<-nc_open(paste0(dir_gf,'ancillary_data/spatialweights_usbr12km_nhru_conus_mod.nc'))
dim_data<-ncvar_get(nc_id,'data')
dim_polyid<-ncvar_get(nc_id,'polyid')
length(unique(dim_data))==length(dim_data)     # grid ID??
length(unique(dim_polyid))==length(dim_polyid) # POLYID

i_index<-ncvar_get(nc_id,'i_index')
j_index<-ncvar_get(nc_id,'j_index')
summary(i_index) # goes until 463, when maurer has 462 and livneh 464 col, weird

nc_close(nc_id)
