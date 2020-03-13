rm(list=ls())

require(ncdf4)
require(RColorBrewer)

dir_plots<-'/glade/u/home/naddor/plots/calib_camels/'
dir_r_scripts<-'/glade/u/home/naddor/scripts/r_scripts/'

source(paste0(dir_r_scripts,'camels/hydro/hydro_accuracy.R'))
source(paste0(dir_r_scripts,'camels/hydro/hydro_signatures.R'))
source(paste0(dir_r_scripts,'camels/maps/plot_maps_camels.R'))

source(paste0(dir_r_scripts,'tofu/load_nc_data.R'))
source(paste0(dir_r_scripts,'tofu/set_default_paths.R'))
source(paste0(dir_r_scripts,'tofu/set_camels_paths.R'))

load_camels_data('2.1')

### DEFINE CALIBRATION AND EVALUATION PERIODS
# Andy: "The calibration period was WY2000-2008 and validation was WY1990-1999.
# For calibration,we started the model 1 January 1990 and let it spin up for 10 years.
# For validation, we started the model at 1 January 1980 and let it spin up for 10 years."
date_start_calib='19991001'
date_end_calib='20080930'

date_start_eval='19891001'
date_end_eval='19990930'

# data structures
cal<-list() # for metrics based on calibrated runs
reg<-list() # for metrics based on regionalised runs

list_var<-c('nse','qmea','bfi','sfdc')
list_fuse<-c('900','902','904')
n_gauges<-length(camels_name$gauge_id)

nse_structure<-as.data.frame(array(dim=c(n_gauges,4)));colnames(nse_structure)<-c('gauge_id',list_fuse)
nse_structure$gauge_id<-camels_name$gauge_id
hs_structure<-as.data.frame(array(dim=c(n_gauges,5)));colnames(hs_structure)<-c('gauge_id','obs',list_fuse)
hs_structure$gauge_id<-camels_name$gauge_id

for (my_var in list_var){

  if(my_var=='nse'){

    cal[[my_var]]<-nse_structure

  } else {

    cal[[my_var]]<-hs_structure

  }
}

### SET FUSE STRUCTURE
for (fuse_id in list_fuse){

  ### SET DIRS
  dir_output<-paste0('/glade/scratch/naddor/fuse/param_transfer_maurer/output_',fuse_id,'/')

  # create data strctures
  my_file<-list()       # to store file names from def and best simulations
  nse_camels<-list()
  nse_camels[['eval_def']]<-array()
  nse_camels[['eval_best']]<-array()
  nse_camels[['calib_best']]<-array()

  for(my_gauge_id in camels_name$gauge_id){ # only catchments for which calibrated runs available

    my_file[['best']]<-paste0(dir_output,'us_',my_gauge_id,'_',fuse_id,'_runs_best.nc')
    my_file[['def']]<-paste0(dir_output,'us_',my_gauge_id,'_',fuse_id,'_runs_def.nc')

    e<-which(my_gauge_id==camels_name$gauge_id)

    if(all(file.exists(unlist(my_file)))){

      for(fuse_mode in c('def','best')){ # leave 'best' after 'def'

        # load FUSE simulation
        read_nc_output(my_file[[fuse_mode]])

        # determine calib and eval periods
        i_calib<-d_output>=as.Date(date_start_calib,'%Y%m%d')&d_output<=as.Date(date_end_calib,'%Y%m%d')
        i_eval<-d_output>=as.Date(date_start_eval,'%Y%m%d')&d_output<=as.Date(date_end_eval,'%Y%m%d')

        # compute NSE
        nse_camels[[paste0('calib_',fuse_mode)]][e]<-compute_nse(obs=qobs[i_calib],sim=qsim[i_calib])
        nse_camels[[paste0('eval_',fuse_mode)]][e]<-compute_nse(obs=qobs[i_eval],sim=qsim[i_eval])

      }

      # compute NSE and signatures over eval period for calibrated simulations
      cal[['nse']][e,fuse_id]<-compute_nse(obs=qobs[i_eval],sim=qsim[i_eval])
      cal[['qmea']][e,fuse_id]<-compute_q_mean(qsim[i_eval],d=d_output[i_eval])$q_mean_yea
      cal[['bfi']][e,fuse_id]<-comp_i_bf_landson(qsim[i_eval])
      cal[['sfdc']][e,fuse_id]<-comp_s_fdc(qsim[i_eval])$sfdc_addor_2017

      if(fuse_id==list_fuse[1]){ # when considering the first model, compute observed signatures

        cal[['qmea']][e,'obs']<-compute_q_mean(qobs[i_eval],d=d_output[i_eval])$q_mean_yea
        cal[['sfdc']][e,'obs']<-comp_s_fdc(qobs[i_eval])$sfdc_addor_2017

        if(!any(is.na(qobs[i_eval]))){ # only compute BFI if not streamflow data missing

          cal[['bfi']][e,'obs']<-comp_i_bf_landson(qobs[i_eval])

        } else {

          cal[['bfi']][e,'obs']<-NA

        }
      }
    }
  }
}

# CREATE MAPS

pdf(paste0(dir_plots,'param_transfer_maurer/fig2.pdf'),width=8,height=8,useDingbats=FALSE)

  plot_map_catch_attr(cal[['nse']],c(2,3,4))

dev.off()


### CDF NSE
ecdf_calib_def<-ecdf(nse_camels[['calib_def']])
ecdf_eval_def<-ecdf(nse_camels[['eval_def']])

ecdf_calib_best<-ecdf(nse_camels[['calib_best']])
ecdf_eval_best<-ecdf(nse_camels[['eval_best']])

pdf(paste0(dir_plots,'NSE_CDF_all_param_maurer',fuse_id,'.pdf'),width = 6,height=6,useDingbats = FALSE)

  par(mar=c(4,4,2,0.5))

  #par(mfrow=c(1,2))

  plot(0,0,xlab='NSE',xlim=c(0,1),ylim=c(0,1),'n',ylab='F(x)')
  lines(ecdf_calib_def,col='black',lty=2)
  lines(ecdf_calib_best,col='orange')
  lines(ecdf_eval_best,col='red')

  abline(v=seq(0.1,1,0.2),h=seq(0.1,1,0.2),lty=3,lwd=0.5)

  legend('topleft',c('SCE - cal','SCE - val','DEF'),col=c('orange','red','black'),lwd=2)

dev.off()

# export data for benchmark study
dat_export<-data.frame(basin_id=station_id_from_file,cal_nse=nse_camels[['calib_best']],val_nse=nse_camels[['eval_best']],def_nse=nse_camels[['eval_def']])

write.table(dat_export,paste0('/glade/u/home/naddor/fuse_maurer_nse_',fuse_id,'.txt'),sep=' ',row.names=FALSE,quote=FALSE)

# # test param VALUES
# nic_sce<-nc_open(paste0('/glade/scratch/naddor/fuse/param_transfer_maurer/output_',fuse_id,'/us_',station_id,'_',fuse_id,'_para_sce.nc'))
# sce_nse<-ncvar_get(nic_sce,'nash_sutt')
# sce_rmse<-ncvar_get(nic_sce,'raw_rmse')
# sce_i<-sce_nse<1
# i_best<-which.min(sce_rmse)
# plot(sce_nse[sce_i],ylim=c(0,1))
# points(i_best,sce_nse[i_best],pch=16,col='red')
#
# ncvar_get(nic_sce,'MBASE')[i_best]
# i_best
#
# # test
# i2p<-3000:4000
# par(mfrow=c(2,2),mar=c(4,4,2,0.5))
# plot(d_output[i2p],qobs[i2p],type='l',xlab='')
# lines(d_output[i2p],qsim[i2p],col='orange',type='l',xlab='')
# plot(d_output[i2p],swe[i2p],col='blue',type='l',xlab='')
# plot(qobs,qsim)

#legend('topleft',c(fuse_models,'uncalibrated','SCE_calibrated'),col=c(col_900,col_901,col_902,'black','black'),pch=c(15,15,15,16,8),bg='white')

#plot(ecdf_nse_sce_902_900,col='white',xlab='NSE',main='NSE difference over calibration period',xlim=c(-1,1))
#polygon(x=c(-0.1,0.1,0.1,-0.1),y=c(-2,-2,2,2),col='gray90',border=NA)
#lines(ecdf_nse_sce_902_900,col='darkorchid1')
#lines(ecdf_nse_sce_902_901,col='cadetblue3')
#abline(v=seq(-1.2,1.2,0.2),h=seq(-1.2,1.2,0.2),lty=3,lwd=0.5)

#legend('topleft',c('VIC - HMS','VIC - VIC-nosnow'),col=c('darkorchid1','cadetblue3'),pch=16,bg='white')

#dev.off()
