rm(list=ls())

library(ncdf4)

dir_gf<-'/gpfs/ts0/projects/Research_Project-CLES-00008/mizuroute_data/GF_conus/'

### LOAD NETWORK INFORMATION
nc_id<-nc_open(paste0(dir_gf,'ancillary_data/ntopo_GF_conus.nc'))
nc_id # seg_id  Size:57116
      # hruid   Size:110572

seg_id<-ncvar_get(nc_id,'seg_id')
lat_start<-ncvar_get(nc_id,'start_lat')
lon_start<-ncvar_get(nc_id,'start_lon')
lat_end<-ncvar_get(nc_id,'end_lat')
lon_end<-ncvar_get(nc_id,'end_lon')

hru_id<-ncvar_get(nc_id,'hruid')
lat_centro_hru<-ncvar_get(nc_id,'Lat_Centro')
lon_centro_hru<-ncvar_get(nc_id,'Lon_Centro')
seg_hru_id<-ncvar_get(nc_id,'seg_hru_id')


nc_close(nc_id)

# approximate length of each segment (assuming straight line)
length_seq<-sqrt((lat_start-lat_end)^2+(lon_start-lon_end)^2)

summary(length_seq*100) # rough conversion deg to km

### PLOT NETWORK
pdf(paste0(dir_plots,'fuse_gmd/mizu/plot_network.pdf'),10,10)
plot(lon_end,lat_end,type='n')
apply(cbind(lon_start,lat_start,lon_end,lat_end),1,function(x)lines(c(x[1],x[3]),c(x[2],x[4]),col='blue'))
dev.off()

### LOAD HRU mapping

nc_id<-nc_open(paste0(dir_gf,'ancillary_data/spatialweights_usbr12km_nhru_conus_mod.nc'))
nc_id # data     Size:377850
      # polyid   Size:110572

poly_id<-ncvar_get(nc_id,'polyid')
all(poly_id%in%hru_id) # TRUE, but not in same order

i_index<-ncvar_get(nc_id,'i_index')
j_index<-ncvar_get(nc_id,'j_index')
summary(i_index)
summary(j_index)
463*222

# for each HRU,
overlaps<-ncvar_get(nc_id,'overlaps') # how many grid cell does it overlap with?
summary(overlaps)

# for each grid cell
weight<-ncvar_get(nc_id,'weight') # which HRU does it overlap?
length(overlapPolyId)
summary(weight)
overlapPolyId<-ncvar_get(nc_id,'overlapPolyId') # which HRU does it overlap?
summary(overlapPolyId)


summary(i_index)
summary(j_index)

### GET MIZU OUTPUT - streamflow is at the exist of reach.
nc_id<-nc_open(paste0(dir_gf,'output/q_grid_mapping_1950-1-1.nc'))
# seg_output<-ncvar_get(nc_id,'seg') # CANNOT
sumUpstreamRunoff<-ncvar_get(nc_id,'sumUpstreamRunoff')
instRunoff<-ncvar_get(nc_id,'instRunoff')
KWTroutedRunoff<-ncvar_get(nc_id,'KWTroutedRunoff')
IRFroutedRunoff<-ncvar_get(nc_id,'IRFroutedRunoff')

dim(sumUpstreamRunoff)
length(seg_id)

nc_close(nc_id)

### PLOT TIMESERIES FOR ONE SEGMENT
my_seg<-6656
plot(sumUpstreamRunoff[my_seg,],type='l')
lines(instRunoff[my_seg,],type='l',col='red') # lower than the others
lines(KWTroutedRunoff[my_seg,],type='l',col='blue')
lines(IRFroutedRunoff[my_seg,],type='l',col='orange')

### SPATIAL WEIGHTS NETCDF FILES

# get spatial weight maurer
nc_id<-nc_open(paste0(dir_gf,'ancillary_data/spatialweights_usbr12km_nhru_conus_mod.nc'))
dim_data<-ncvar_get(nc_id,'data')
dim_polyid<-ncvar_get(nc_id,'polyid')

length(dim_polyid)

i_index<-ncvar_get(nc_id,'i_index')
j_index<-ncvar_get(nc_id,'j_index')
summary(i_index) # goes until 463, when maurer has 462 and livneh 464 col, weird

nc_close(nc_id)

### RUNOFF NETCDF FILES

# Maurer mizuroute

seg_maurer<-ncvar_get(nc_id,'seg')

plot(sum_up[123,],type='l')

nc_close(nc_id)
