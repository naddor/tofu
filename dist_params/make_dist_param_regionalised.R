rm(list=ls())

require(ncdf4)

# set dir
dir_param<-'/gpfs/ts0/projects/Research_Project-CLES-00008/fuse/fuse_grid/output/'

# open standard (one catchment) parameter file
nc_file_runs_dist<-'cesm1-cam5_902_runs_def.nc'           # for lat/lon
nc_file_para_lumped<-'cesm1-cam5_902_para_def.nc'         # template for variables name, long name and unit
nc_file_para_dist<-'cesm1-cam5_902_para_def_dist_new.nc' # will be created

# get lat and lon from runs
nc_id_runs<-nc_open(paste0(dir_param,nc_file_runs_dist))
longitude<-ncvar_get(nc_id_runs,'longitude')
latitude<-ncvar_get(nc_id_runs,'latitude')
nc_close(nc_id_runs)

# open and process parameter file
nc_id_param_lumped<-nc_open(paste0(dir_param,nc_file_para_lumped))
all_vars<-nc_id_param_lumped['var'][[1]]
var_names<-names(all_vars) # get var names
var_longname<-as.character(unlist(lapply(all_vars,function(x){x['longname']})))
var_units<-as.character(unlist(lapply(all_vars,function(x){x['units']})))

# create distributed parameter file
dim_lon<-ncdim_def("longitude","degreesE",longitude)
dim_lat<-ncdim_def("latitude","degreesN",latitude)
na_value=-9999

nc_var_list<-list() # list for all NetCDF variables

var_to_include<-1:which(var_names=='LAPSE') # LAPSE is the last adjustable parameter

# define variables
for(v in var_to_include){

  nc_var_list[[v]]<-ncvar_def(var_names[v],var_units[v],dim=list(dim_lon,dim_lat),missval=na_value,
                longname=var_longname[v])

}

# write variables to file
nc_conn<-nc_create(paste0(dir_param,nc_file_para_dist),nc_var_list)

for(v in var_to_include){

  var_val<-as.vector(ncvar_get(nc_id_param_lumped,var_names[v]))

  if(var_names[v]=='RFERR_MLT'){ # don't introduce perturbation in rainfall multiplier

    para_dist<-array(var_val*rnorm(length(longitude)*length(latitude),mean=1,0))

  }else{

    para_dist<-array(var_val*rnorm(length(longitude)*length(latitude),mean=1,sd=0.3))

  }

  ncvar_put(nc_conn,nc_var_list[[v]],vals=para_dist)

}

nc_close(nc_id_param_lumped)
nc_close(nc_conn)
