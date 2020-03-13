
source(paste0(dir_r_scripts,'camels/hydro/hydro_accuracy.R'))
source(paste0(dir_r_scripts,'camels/hydro/hydro_signatures.R'))

compute_nse_hs<-function(obs,sim){

  nse<-compute_nse(obs,sim)
  e_qmean<-mean(obs,na.rm=TRUE)/mean(sim,na.rm=TRUE)-1
  e_sfdc<-comp_s_fdc(sim)$sfdc_addor_2017/comp_s_fdc(obs)$sfdc_addor_2017-1

  if((sum(is.na(obs))/length(obs)<0.05)&(sum(is.na(sim))/length(sim)<0.05)){

    e_bfi<-comp_i_bf_landson(obs)/comp_i_bf_landson(sim)-1

  } else {

    e_bfi<-NA

  }

  return(data.frame(nse=nse,e_qmean=e_qmean,e_bfi=e_bfi,e_sfdc=e_sfdc))

}
