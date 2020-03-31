rm(list=ls())

library(ncdf4)
library(RColorBrewer)
library(stats)

# SET GENERIC PATHS
#source(paste0(dir_r_scripts,'/tofu/set_default_paths.R'))  # set all paths))
source(paste0(dir_r_scripts,'/tofu/set_camels_paths.R'))  # set all paths))

source(paste0(dir_r_scripts,'camels/hydro/hydro_accuracy.R'))
#source(paste0(dir_r_scripts,'param_transfer_maurer/compute_nse_hs.R'))

dir_plots<-paste0(dir_plots,'param_transfer_maurer/')

# SET CAMELS PATHS
camels_version<-'2.1'
load_camels_data(camels_version)
#fuse_id_list<-c('904','902','900')
fuse_id_list<-900

### DEFINE EVALUATION PERIODS
date_start_cal='19991001' # cal for benchmark study
date_end_cal='20080930'

date_start_val='19891001' # eval for benchmark study
date_end_val='19990930'

for(fuse_id in fuse_id_list){

  ### SET DIRS
  dir_fuse_output<-paste0('/gpfs/ts0/projects/Research_Project-CLES-00008/camels_us/time_series/output_obs/fuse_output_maurer_isca/',fuse_id,'_test/')

  # get list of simulation files
  files_pre_run<-system(paste0('ls ',dir_fuse_output,'*runs_pre_catch*'),intern=TRUE)
  n_catch<-length(files_pre_run)

  # get list of donor catchments
  donor_catch_raw<-read.table(paste0('/gpfs/ts0/home/na491/fuse/bin/list_param_',fuse_id,'_test.txt'))
  donor_catch<-rapply(strsplit(as.character(donor_catch_raw[,1]),'_'),function(x) x[2]) # retrieve ID of donor catchments

  # add attribute to donor catchments
  catch_att<-merge(data.frame(gauge_id=donor_catch),camels_topo)
  catch_att<-merge(catch_att,camels_clim)

  # create data structures
  my_file<-list()
  nse<-list()     # NSE
  mean_hyd_diff<-list() # Mean hydrological distance to donor catchments

  nse_grid<-array(dim=c(n_catch,n_catch))

  # define measures of hydrologic similarity
  sel_att_list<-list()
  sel_att_list[['dist']]<- c('gauge_lat','gauge_lon','basin_mean_elev')
  sel_att_list[['clim']]<- c('seasonality','frac_snow_daily','aridity')

  for(e in 1:n_catch){

    my_file[['pre']]<-files_pre_run[e]
    station_id<-strsplit(strsplit(my_file[['pre']],'us_')[[1]][2],'_')[[1]][1] # retrieve catch ID from pre_catch file name

    # check that the list of simulated catchments and donor catchment match
    if(catch_att$gauge_id[e]!=station_id){stop('Unexpected gauge_id')}
    print(paste(e,station_id))

    my_file[['def']]<-paste0(dir_fuse_output,'us_',station_id,'_',fuse_id,'_runs_def.nc')

    for (fuse_mode in c('def','pre')){ # leave def before pre

      # open file
      nc_id<-nc_open(my_file[[fuse_mode]])

      # get time
      d_raw<-ncvar_get(nc_id,'time')
      d_unit <-ncatt_get(nc_id,'time')$units
      d_unit_split<-strsplit(d_unit,' ')[[1]]

      if(paste(d_unit_split[1:2],collapse =' ')!='days since'|any(diff(d_raw)!=1)){ # check that we're dealing with daily values

       stop('Unexpected time format.')

      }

      d_origin<-as.Date(d_unit_split[3],'%Y-%m-%d')
      d_sim<-d_origin+d_raw
      m_sim<-format(d_sim,'%m')
      j_sim<-as.numeric(format(d_sim,'%j')) # day of year

      # extract variable
      if(fuse_mode=='def'){ # only here because obsq not outputed to pre, remove when fixed and load from pre output directly
        qobs<-ncvar_get(nc_id,'obsq')

      }

      qsim<-ncvar_get(nc_id,'q_routed')

      nc_close(nc_id)

      # COMPUTE NSE FOR DIFFERENT REGIONALISATION TECHNIQUES
      # determine evaluation period
      i_val<-d_sim>=as.Date(date_start_val,'%Y%m%d')&d_sim<=as.Date(date_end_val,'%Y%m%d')
      i_cal<-d_sim>=as.Date(date_start_cal,'%Y%m%d')&d_sim<=as.Date(date_end_cal,'%Y%m%d')

      if(fuse_mode=='def'){

        # NSE using default parameter values
        #if(station_id!='07373000'){
          nse[['def']][e]<-compute_nse(obs=qobs[i_val],sim=qsim[i_val])
        #}else{
        #  nse[['def']][e]<-NA
        #}

      } else if(fuse_mode=='pre'){

        # compute NSE for SCE calibration
        i_catch<-which(donor_catch==station_id) # indice of run done with SCE calibration for this catchment

        nse[['sce_cal']][e]<-compute_nse(obs=qobs[i_cal],sim=qsim[i_catch,i_cal])
        nse[['sce_val']][e]<-compute_nse(obs=qobs[i_val],sim=qsim[i_catch,i_val])

      }
    }

    # compute NSE when each catchment is used as donor
    for (donor in 1:n_catch){

      nse_grid[e,donor]<-compute_nse(obs=qobs[i_val],sim=qsim[donor,i_val])

    }

    # compute NSE when a ensemble made of all the parameter sets is used
    nse[['all']][e]<-compute_nse(obs=qobs[i_val],sim=colMeans(qsim[,i_val]))

    # select most similar catchments
    for(sim_measure in names(sel_att_list)){

      sel_att<-sel_att_list[[sim_measure]]           # attibute based on which similarity will be defined
      sel_att_iqr<-apply(catch_att[,sel_att],2,IQR)  # variability in those attributes
      hyd_diff_raw<-sweep(as.matrix(catch_att[,sel_att]),MARGIN=2,as.matrix(catch_att[e,sel_att]),FUN="-") # compute difference
      hyd_diff_scaled<-sweep(as.matrix(hyd_diff_raw[,sel_att]),MARGIN=2,as.matrix(sel_att_iqr),FUN="/")    # scale difference
      hyd_diff<-rowSums(abs(hyd_diff_scaled))  # compute aggreggated difference metric

      closest_neigh<-order(hyd_diff)

      if(closest_neigh[1]!=e){

        stop('The closest catchment is not the catchment itself!')

      } else {

        closest_neigh<-closest_neigh[-1] # remove the catchment itself

      }

      for(num_neigh in c(3,10)){

        nse[[paste(sim_measure,num_neigh,sep='_')]][e]<-compute_nse(obs=qobs[i_val],sim=colMeans(qsim[closest_neigh[1:num_neigh],i_val]))
        mean_hyd_diff[[paste(sim_measure,num_neigh,sep='_')]][e]<-mean(hyd_diff[closest_neigh[1:num_neigh]])

      }
    }
  }

  # GET NSE FOR THE ONE DONOR LEADING TO HIGHEST MEDIAN NSE
  best_donor<-which.max(apply(nse_grid,2,median,na.rm=TRUE))
  nse[['best']]<-nse_grid[,best_donor]

  ### SAVE WORKSPACE
  save.image(paste0('/gpfs/ts0/projects/Research_Project-CLES-00008/fuse_gmd/regio/nse_hs_',fuse_id,'with_def.Rdata'))

}
