rm(list=ls())

require(ncdf4)
require(RColorBrewer)
require(stats)

# SET GENERIC PATHS
hostname<-system('hostname',intern=TRUE)

if(hostname=='hydro-c1'){

  source('/home/naddor/scripts/r_scripts/tofu/set_default_paths.R')  # set all paths

} else {

  source('/glade/u/home/naddor/scripts/r_scripts/tofu/set_default_paths.R')  # set all paths
  source('/glade/u/home/naddor/scripts/r_scripts/tofu/set_camels_paths.R')

}

source(paste0(dir_r_scripts,'camels/hydro/hydro_accuracy.R'))
source(paste0(dir_r_scripts,'param_transfer_maurer/compute_nse_hs.R'))

dir_plots<-paste0(dir_plots,'param_transfer_maurer/')

# SET CAMELS PATHS
camels_version<-'2.1'
load_camels_data(camels_version)
fuse_id_list<-c('904','902','900')

### DEFINE EVALUATION PERIODS
date_start_cal='19991001' # cal for benchmark study
date_end_cal='20080930'

date_start_val='19891001' # eval for benchmark study
date_end_val='19990930'

for(fuse_id in fuse_id_list){

  ### SET DIRS
  dir_fuse_output<-paste0('/glade/scratch/naddor/fuse/param_transfer_maurer/output_',fuse_id,'/')

  # get list of simulation files
  files_pre_run<-system(paste0('ls ',dir_fuse_output,'*runs_pre*'),intern=TRUE)
  n_catch<-length(files_pre_run)

  # get list of donor catchments
  donor_catch_raw<-read.table(paste0('/glade/u/home/naddor/fuse/bin/list_param_all_',fuse_id,'.txt'))
  donor_catch<-rapply(strsplit(as.character(donor_catch_raw[,1]),'_'),function(x) x[2])

  catch_att<-merge(data.frame(gauge_id=donor_catch),camels_topo)
  catch_att<-merge(catch_att,camels_clim)

  # create data strcture
  my_file<-list()
  nse<-list()     # NSE
  e_qmean<-list() # Relative error in mean discharge
  e_bfi<-list()   # Relative error in baseflow index
  e_sfdc<-list()  # Relative error in slope of the flow duration curve
  mean_hyd_diff<-list() # Mean hydrological distance to donor catchments

  nse_grid<-array(dim=c(n_catch,n_catch))

  # define measure of hydrologic similarity
  sel_att_list<-list()
  sel_att_list[['dist']]<- c('gauge_lat','gauge_lon','basin_mean_elev')
  sel_att_list[['clim']]<- c('seasonality','frac_snow_daily','aridity')

  for(e in 1:n_catch){

    # e=431  for sopron
    my_file[['pre']]<-files_pre_run[e]
    station_id<-strsplit(strsplit(my_file[['pre']],'us_')[[1]][2],'_')[[1]][1]
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
      j_sim<-as.numeric(format(d_sim,'%j'))
      reorder_j<-c(j_sim[1]:365,1:(j_sim[1]-1)) # 365 and not 366

      # extract variable
      qobs<-ncvar_get(nc_id,'obsq')
      qsim<-ncvar_get(nc_id,'q_routed')
      #swe<-ncvar_get(nc_id,'swe_tot')
      #et<-ncvar_get(nc_id,'evap_1')+ncvar_get(nc_id,'evap_2')
      #sm<-ncvar_get(nc_id,'watr_1')+ncvar_get(nc_id,'watr_2')

      nc_close(nc_id)

      # COMPUTE NSE FOR DIFFERENT REGIONALISATION TECHNIQUE
      # determine evaluation period
      i_val<-d_sim>=as.Date(date_start_val,'%Y%m%d')&d_sim<=as.Date(date_end_val,'%Y%m%d')
      i_cal<-d_sim>=as.Date(date_start_cal,'%Y%m%d')&d_sim<=as.Date(date_end_cal,'%Y%m%d')

      if(fuse_mode=='def'){

        if(station_id!='07373000'){

          res_def<-compute_nse_hs(obs=qobs[i_val],sim=qsim[i_val])

          nse[['def']][e]<-res_def$nse
          e_qmean[['def']][e]<-res_def$e_qmean
          e_bfi[['def']][e]<-res_def$e_bfi
          e_sfdc[['def']][e]<-res_def$e_sfdc

        }else{
          nse[['def']][e]<-NA
          e_qmean[['def']][e]<-NA
          e_bfi[['def']][e]<-NA
          e_sfdc[['def']][e]<-NA

        }

      } else if(fuse_mode=='pre'){

        # compute NSE for SCE calibration
        i_catch<-which(donor_catch==station_id) # indice of run done with SCE calibration for this catchment

        res_sce_cal<-compute_nse_hs(obs=qobs[1,i_cal],sim=qsim[i_catch,i_cal])
        nse[['sce_cal']][e]<-res_sce_cal$nse
        e_qmean[['sce_cal']][e]<-res_sce_cal$e_qmean
        e_bfi[['sce_cal']][e]<-res_sce_cal$e_bfi
        e_sfdc[['sce_cal']][e]<-res_sce_cal$e_sfdc

        res_sce_val<-compute_nse_hs(obs=qobs[1,i_val],sim=qsim[i_catch,i_val])
        nse[['sce_val']][e]<-res_sce_val$nse
        e_qmean[['sce_val']][e]<-res_sce_val$e_qmean
        e_bfi[['sce_val']][e]<-res_sce_val$e_bfi
        e_sfdc[['sce_val']][e]<-res_sce_val$e_sfdc

      }

    }

    # compute NSE when each catchment is used as donor
    for (donor in 1:n_catch){

      nse_grid[e,donor]<-compute_nse(obs=qobs[1,i_val],sim=qsim[donor,i_val])

    }

    # compute NSE when a ensemble made of all the parameter sets is used
    res_all<-compute_nse_hs(obs=qobs[i_catch,i_val],sim=colMeans(qsim[,i_val]))
    nse[['all']][e]<-res_all$nse
    e_qmean[['all']][e]<-res_all$e_qmean
    e_bfi[['all']][e]<-res_all$e_bfi
    e_sfdc[['all']][e]<-res_all$e_sfdc

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

        res_reg<-compute_nse_hs(obs=qobs[1,i_val],sim=colMeans(qsim[closest_neigh[1:num_neigh],i_val]))
        nse[[paste(sim_measure,num_neigh,sep='_')]][e]<-res_reg$nse
        e_qmean[[paste(sim_measure,num_neigh,sep='_')]][e]<-res_reg$e_qmean
        e_bfi[[paste(sim_measure,num_neigh,sep='_')]][e]<-res_reg$e_bfi
        e_sfdc[[paste(sim_measure,num_neigh,sep='_')]][e]<-res_reg$e_sfdc

        mean_hyd_diff[[paste(sim_measure,num_neigh,sep='_')]][e]<-mean(hyd_diff[closest_neigh[1:num_neigh]])

      }
    }
  }

  # GET NSE FOR THE ONE DONOR LEADING TO HIGHEST MEDIAN NSE
  best_donor<-which.max(apply(nse_grid,2,median,na.rm=TRUE))
  nse[['best']]<-nse_grid[,best_donor]

  ### SAVE WORKSPACE
  save.image(paste0('/glade/u/home/naddor/data/para_transfer_maurer/nse_hs_',fuse_id,'with_def.Rdata'))

}
