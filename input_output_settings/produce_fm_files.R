rm(list=ls())

hostname<-system('hostname',intern=TRUE)

if(hostname=='hydro-c1'){

  source('/home/naddor/scripts/r_scripts/tofu/set_default_paths.R')

} else if(strtrim(hostname,8)=='cheyenne'){

  source('/glade/u/home/naddor/scripts/r_scripts/tofu/set_default_paths.R')

} else {

  stop(paste('Unknown hostname:',hostname))

}

fuse_id=902
forcing_dataset<-'maurer'

source(paste(dir_r_scripts,'tofu/create_settings.R',sep=''))

dir_fuse_bin<-paste0(dir_home,'fuse/bin/')
dir_fuse_files<-paste0('/glade/scratch/naddor/fuse/param_transfer_',forcing_dataset,'/')
dir_input<-paste0(dir_fuse_files,'input/'); if(!dir.exists(dir_input)){dir.create(dir_input)}
dir_output<-paste0(dir_fuse_files,'output_',fuse_id,'/'); if(!dir.exists(dir_output)){dir.create(dir_output)}
dir_settings<-paste0(dir_fuse_files,'settings/'); if(!dir.exists(dir_settings)){dir.create(dir_settings)}

# define period for the hydrological simulations
# Andy: "The calibration period was WY2000-2008 and validation was WY1990-1999.
# For calibration,we started the model 1 January 1990 and let it spin up for 10 years.
# For validation, we started the model at 1 January 1980 and let it spin up for 10 years."

for (exp_name in c('cal','val','all')){

  if(exp_name=='cal'){

    # Calibration benchmark study
    date_start_sim<-'1990-01-01'
    date_end_sim<-'2008-09-30'
    date_start_eval<-'1999-10-01'
    date_end_eval<-'2008-09-30'   # same as date_end_sim

  }else if(exp_name=='val'){

    # Evaluation benchmark study
    date_start_sim<-'1980-01-01'
    date_end_sim<-'1999-09-30'
    date_start_eval<-'1989-10-01'
    date_end_eval<-'1999-09-30'   # same as date_end_sim

  }else{

    date_start_sim<-'1980-01-01'
    date_end_sim<-'2008-12-31'
    date_start_eval<-'1985-10-01'
    date_end_eval<-'2008-12-31'   # same as date_end_sim

  }

  # create file manager files
  name_file_manager<-paste0('fm_',fuse_id,'_',forcing_dataset,'_benchmark_',exp_name,'.txt')
  path_file_manager<-paste0(dir_fuse_bin,name_file_manager)

  write_file_manager(path_file_manager,dir_input,dir_output,dir_settings,fuse_id,
                     date_start_sim,date_end_sim,date_start_eval,date_end_eval)

}
