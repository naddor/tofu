write_fuse_input_info<-function(file_name,nc_input_file,warmup_beg,infern_beg,infern_end,longrun_beg,longrun_end,numtim_sub){

  content<-paste('! used to define information for the forcing file
! -----------------------------------------------------------------------------------------------------------
! lines starting with exclamation marks are not read
! (variables can be in any order)
! -----------------------------------------------------------------------------------------------------------
<version>         FORCINGINFO.VERSION.2.1              ! string to ensure version of file matches the code
<forcefile>       ',nc_input_file,' ! name of data file
<vname_iy>        undefined                            ! name of variable for year
<vname_im>        undefined                            ! name of variable for month
<vname_id>        undefined                            ! name of variable for day
<vname_ih>        undefined                            ! name of variable for hour
<vname_imin>      undefined                            ! name of variable for minute
<vname_dsec>      undefined                            ! name of variable for second
<vname_dtime>     time                                 ! time since reference time
<vname_aprecip>   pr                                   ! variable name: precipitation
<vname_airtemp>   temp                                 ! variable name: temperature
<vname_spechum>   undefined                            ! variable name: specific humidity
<vname_airpres>   undefined                            ! variable name: surface pressure
<vname_swdown>    undefined                            ! variable name: downward shortwave radiation
<vname_potevap>   pet                                  ! variable name: potential ET
<vname_q>         q_obs                                ! variable name: runoff
<units_aprecip>   mm/d                                 ! units: precipitation
<units_airtemp>   degC                                 ! units: temperature
<units_spechum>   undefined                            ! units: specific humidity
<units_airpres>   undefined                            ! units: surface pressure
<units_swdown>    undefined                            ! units: downward shortwave radiation
<units_potevap>   mm/d                                 ! units: potential ET
<units_q>         mm/d                                 ! units: runoff
<deltim>          1.0                                  ! time step (days)
<xlon>            -75.00                               ! longitude
<ylat>              4.00                               ! latitude
<warmup_beg>      ',warmup_beg,'                                 ! start index for the warm-up period
<infern_beg>      ',infern_beg,'                                 ! start index for the inference period
<infern_end>      ',infern_end,'                                 ! end index for the inference period
<longrun_beg>      ',longrun_beg,'                                 ! start index for the long run
<longrun_end>      ',longrun_end,'                                 ! end index for the lon run
<numtim_sub>      ',numtim_sub,'                                 ! number of time steps per subperiod',sep='')

  fileConn<-file(file_name)
  writeLines(content, fileConn)
  close(fileConn)

}

write_fuse_file_manager<-function(file_name,dir_input,dir_output,dir_settings,fuse_id){

  content<-paste('FUSE_FILEMANAGER_V1.1
!Empty command line
! *** paths
\'',dir_settings,'\'    ! SETNGS_PATH
\'',dir_input,'\'       ! INPUT_PATH
\'',dir_output,'\'      ! OUTPUT_PATH
! *** control files
\'forcinginfo.XXXXXXXX.txt\'       ! FORCINGINFO = info on forcing data files [not used in BATEAU_DK]
\'mbands_info.XXXXXXXX.txt\'       ! MBANDS_INFO = info on basin bands datafile
\'fuse_zDecisions_',fuse_id,'.txt\'        ! M_DECISIONS = definition of model decisions
\'fuse_zConstraints_snow.txt\'     ! CONSTRAINTS = definition of parameter constraints
\'fuse_zNumerix.txt\'              ! MOD_NUMERIX = definition of numerical solution technique
\'batea_param.txt\'                ! BATEA_PARAM = definition of BATEA parameters [not used in BATEAU_DK]',sep='')

  fileConn<-file(file_name)
  writeLines(content, fileConn)
  close(fileConn)

}
