# Purpose: create a distributed parameter file for the grid test case with two
# perturbed parameters in order to visually check that these petrubations are
# propagated when the FUSE distributed parameter mode is used.

rm(list=ls())

library(ncdf4)

# set dir
dir_param<-'/gpfs/ts0/projects/Research_Project-CLES-00008/fuse/case_studies/fuse_grid/output/'

# open standard run and parameter file to use as templates
nc_file_runs_dist<-'cesm1-cam5_902_runs_def.nc'     # for lat/lon
nc_file_para_lumped<-'cesm1-cam5_902_para_def.nc'   # template for parameter name, long name and unit
nc_file_para_dist<-'cesm1-cam5_902_para_pert.nc'    # will be created

# get lat and lon from runs
nc_conn_runs<-nc_open(paste0(dir_param,nc_file_runs_dist))
longitude<-ncvar_get(nc_conn_runs,'longitude')
latitude<-ncvar_get(nc_conn_runs,'latitude')
nc_close(nc_conn_runs)

# open and process parameter file
ncc_para_def<-nc_open(paste0(dir_param,nc_file_para_lumped))
all_vars<-ncc_para_def['var'][[1]]
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
ncc_para_pert<-nc_create(paste0(dir_param,nc_file_para_dist),nc_var_list)

for(v in var_to_include){

  # retrieve default parameter value and use it accross domain
  var_val<-as.vector(ncvar_get(ncc_para_def,var_names[v]))
  para_dist<-matrix(var_val,length(longitude),length(latitude))

  # create perturbation (square lower left corner) for the multiplicative rainfall factor
  if(var_names[v]=='RFERR_MLT'){ # only change
    para_dist<-para_dist/2
    para_dist[1:15,1:15]<-var_val*2
  }

  # create perturbation (square upper right corner) for percolation
  if(var_names[v]=='PERCRTE'){ # only change
    para_dist<-para_dist/2
    para_dist[length(longitude)-0:14,length(latitude)-0:14]<-var_val*10
  }

  ncvar_put(ncc_para_pert,nc_var_list[[v]],vals=para_dist)

}

nc_close(ncc_para_def)
nc_close(ncc_para_pert)
