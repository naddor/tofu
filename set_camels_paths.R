
# function to set paths to CAMELS directories
set_camels_paths<-function(camels_version){

  # data_raw
  dir_catch_attr<<-paste0(dir_data,'basin_attributes/data_raw/camels_attributes_v',camels_version,'/') # set directory in which to save the catchment attributes
  dir_catch_attr_temp<<-paste0(dir_catch_attr,'temp/') # set directory in which to temporarily save the catchment attributes
  print(paste('dir_catch_attr:    ',dir_catch_attr))

  # data_public
  dir_camels_public<<-paste0(dir_data,'basin_attributes/data_public/camels_attributes_v',camels_version,'/')
  print(paste('dir_camels_public: ',dir_camels_public))

  # data for CAMELS
  dir_mpr_input<<-paste(dir_root,'home/mizukami/MPR/input/',sep='')
  dir_statsgo_mapping<<-paste(dir_root,'d3/mizukami/domain_huc/poly2poly_weight/ToHCDN/',sep='')
  dir_r_scripts_catch_attr<<-paste(dir_r_scripts,'catch_clustering/',sep='')

}

# function to load all the attributes into the global environment
load_camels_data<-function(camels_version){

  set_camels_paths(camels_version)

  print(paste('loading attr. from:',dir_camels_public))

  # note that '<<-' created the variables in the global environment
  camels_name<<-read.table(file=paste(dir_camels_public,'camels_name.txt',sep=''),
                          header=TRUE,sep=';',quote='')
  camels_topo<<-read.table(file=paste(dir_camels_public,'camels_topo.txt',sep=''),
                          header=TRUE,sep=';',quote='')
  camels_clim<<-read.table(file=paste(dir_camels_public,'camels_clim.txt',sep=''),
                          header=TRUE,sep=';',quote='')
  camels_hydro<<-read.table(file=paste(dir_camels_public,'camels_hydro.txt',sep=''),
                          header=TRUE,sep=';',quote='')
  camels_vege<<-read.table(file=paste(dir_camels_public,'camels_vege.txt',sep=''),
                          header=TRUE,sep=';',quote='')
  camels_soil<<-read.table(file=paste(dir_camels_public,'camels_soil.txt',sep=''),
                          header=TRUE,sep=';',quote='')
  camels_geol<<-read.table(file=paste(dir_camels_public,'camels_geol.txt',sep=''),
                          header=TRUE,sep=';',quote='')

  camels_name$gauge_id<<-as.factor(sprintf('%08d',camels_name$gauge_id))
  camels_name$huc_02<<-as.factor(sprintf('%02d',camels_name$huc_02))

  camels_topo$gauge_id<<-as.factor(sprintf('%08d',camels_topo$gauge_id))
  camels_clim$gauge_id<<-as.factor(sprintf('%08d',camels_clim$gauge_id))
  camels_hydro$gauge_id<<-as.factor(sprintf('%08d',camels_hydro$gauge_id))
  camels_vege$gauge_id<<-as.factor(sprintf('%08d',camels_vege$gauge_id))
  camels_soil$gauge_id<<-as.factor(sprintf('%08d',camels_soil$gauge_id))
  camels_geol$gauge_id<<-as.factor(sprintf('%08d',camels_geol$gauge_id))

}

# print short instructions
print('Type <set_camels_paths(\'2.0\')> to set all the paths for v2.0')
print('Type <load_camels_data(\'2.0\')> to load all catchment attributes for v2.0')
