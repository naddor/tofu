write_file_manager<-function(file_name,dir_input,dir_output,dir_settings,fuse_id,
                             date_start_sim,date_end_sim,date_start_eval,date_end_eval){

  content<-paste('FUSE_FILEMANAGER_V1.2
!Empty command line
! *** paths
\'',dir_settings,'\'    ! SETNGS_PATH
\'',dir_input,'\'       ! INPUT_PATH
\'',dir_output,'\'      ! OUTPUT_PATH
! *** control files
\'forcinginfo.XXXXXXXX.txt\'       ! FORCINGINFO = info on forcing data files [ignore this line]
\'mbands_info.XXXXXXXX.txt\'       ! MBANDS_INFO = info on basin bands datafile [ignore this line]
\'fuse_zDecisions_',fuse_id,'.txt\'        ! M_DECISIONS = definition of model decisions
\'fuse_zConstraints_snow.txt\'     ! CONSTRAINTS = definition of parameter constraints
\'fuse_zNumerix.txt\'              ! MOD_NUMERIX = definition of numerical solution technique
\'batea_param.txt\'                ! BATEA_PARAM = definition of BATEA parameters [ignore this line]
! *** dates
\'',date_start_sim,'\'                     ! date_start_sim   = date start simulation
\'',date_end_sim,'\'                     ! date_end_sim     = date end simulation
\'',date_start_eval,'\'                     ! date_start_eval  = date start evaluation period
\'',date_end_eval,'\'                     ! date_end_eval    = date end evaluation period
\'-9999\'                          ! numtim_sub       = number of time steps per sub-period [-9999 to run without sub-periods]',sep='')

  fileConn<-file(file_name)
  writeLines(content, fileConn)
  close(fileConn)

}
