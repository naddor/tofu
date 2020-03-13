write_file_manager<-function(file_name,fuse_id,
                             dir_input,dir_output,dir_settings,
                             date_start_sim,date_end_sim,date_start_eval,date_end_eval){

  content<-paste('FUSE_FILEMANAGER_V1.5
! *** paths
\'',dir_settings,'\'    ! SETNGS_PATH
\'',dir_input,'\'       ! INPUT_PATH
\'',dir_output,'\'      ! OUTPUT_PATH
! *** suffic for input files - the files must be in INPUT_PATH
\'_input.nc\'                      ! suffix_forcing     = suffix for forcing file to be append to basin_id
\'_elev_bands.nc\'                 ! suffix_elev_bands  = suffix for elevation bands file to be append to basin_id
! *** settings files - must be in SETNGS_PATH
\'input_info.txt\'                 ! FORCING INFO       = definition of the forcing file
\'fuse_zConstraints_snow.txt\'     ! CONSTRAINTS        = definition of parameter constraints
\'fuse_zNumerix.txt\'              ! MOD_NUMERIX        = definition of numerical solution technique
\'fuse_zDecisions_',fuse_id,'.txt\'        ! M_DECISIONS        = definition of model decisions
! *** output files
\'',fuse_id,'\'                            ! FMODEL_ID          = string defining FUSE model, only used to name output files
\'TRUE\'                ! Q_ONLY            = only write Q to output files (TRUE) or all variables (FALSE)
! *** dates
\'',date_start_sim,'\'                      ! date_start_sim   = date start simulation
\'',date_end_sim,'\'                      ! date_end_sim     = date end simulation
\'',date_start_eval,'\'                      ! date_start_eval  = date start evaluation period
\'',date_end_eval,'\'                      ! date_end_eval    = date end evaluation period
\'-9999\'                              ! numtim_sub       = number of time steps per sub-period [-9999 to run without sub-periods]
! *** SCE parameters - only considered in calib_sce mode
\'10000\'                           ! MAXN          = maximum number of trials before optimization is terminated
\'3\'                               ! KSTOP         = number of shuffling loops the value must change by PCENTO (MAX=9)
\'0.001\'                           ! PCENTO        = the percentage',sep='')

  fileConn<-file(file_name)
  writeLines(content, fileConn)
  close(fileConn)

}
