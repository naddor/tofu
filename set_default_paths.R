hostname<-system('hostname',intern=TRUE)

if(hostname=='hydro-c1'){

  dir_home<-'/home/naddor/'
  dir_root<-'/'

}else if(strtrim(hostname,8)=='cheyenne'){

  dir_home<-'/glade/u/home/naddor/'
  dir_root<-'/on_hydro/'

}else{

  stop(paste('Unkown hostname:',hostname))

}

# set generic paths
dir_basin_dataset<-paste(dir_root,'d7/anewman/basin_dataset_public_v1p2/',sep='')
dir_data<-paste(dir_home,'data/',sep='')
dir_plots<-paste(dir_home,'plots/',sep='')
dir_r_scripts<-paste(dir_home,'scripts/r_scripts/',sep='')
