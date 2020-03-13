


  # PLOT

  if(plot_flag){

    # time steps to plot for a single year
    i_plot<-d_sim>=as.Date('20001001','%Y%m%d')&d_sim<=as.Date('20010930','%Y%m%d')

    wy_str<-paste0('WY',as.numeric(format(d_sim[i_plot][1],'%Y'))+1)
    wp_str<-paste0('WY',as.numeric(format(d_sim[1],'%Y'))+1,'-',
                   'WY',as.numeric(format(d_sim[length(d_sim)],'%Y')))

    col_year<-'deepskyblue3'
    col_ann<-'tomato2'

    pdf(paste0(dir_plots,'param_transfer_',station_id,'.pdf'),width=12,height=6,useDingbats=FALSE)

      par(mfcol=c(2,4),mar=c(2.5,4,4,0.5))

      # Q
      plot(d_sim[i_plot],qobs[1,i_plot],type='n',ylim=c(0,max(rbind(qobs[1,i_plot],qsim[,i_plot]))),
           main=paste('Discharge\n',wy_str),ylab='[mm/day]',xlab='')
      apply(qsim[,i_plot],1,lines,x=d_sim[i_plot],col=col_year)
      lines(d_sim[i_plot],qobs[1,i_plot],col='black')

      qobs_j<-rapply(split(qobs[1,],j_sim),mean,na.rm=TRUE)[reorder_j]
      qsim_j<-t(apply(qsim,1,function(x)rapply(split(x,j_sim),mean)))[,reorder_j]
      plot(d_sim[1:365],qobs_j,ylim=c(0,max(rbind(qobs_j,qsim_j),na.rm=TRUE)),type='n',
        main=paste('Mean discharge\n',wp_str),ylab='[mm/day]',xlab='')
      apply(qsim_j,1,lines,x=d_sim[1:365],col=col_ann)
      lines(d_sim[1:365],qobs_j,col='black')

      # SWE
      plot(d_sim[i_plot],swe[1,i_plot],type='n',ylim=c(0,max(swe[,i_plot])),
        main=paste('SWE\n',wy_str),ylab='[mm]',xlab='')
      apply(swe[,i_plot],1,lines,x=d_sim[i_plot],col=col_year)

      swe_j<-t(apply(swe,1,function(x)rapply(split(x,j_sim),mean)))[,reorder_j]
      plot(d_sim[1:365],swe_j[1:365],ylim=c(0,max(swe_j)),type='n',
        main=paste('Mean SWE\n',wp_str),ylab='[mm]',xlab='')
      apply(swe_j,1,lines,x=d_sim[1:365],col=col_ann)

      # SM
      plot(d_sim[i_plot],sm[1,i_plot],type='n',ylim=c(0,max(sm[,i_plot])),
        main=paste('Soil moisture\n',wy_str),ylab='[mm]',xlab='')
      apply(sm[,i_plot],1,lines,x=d_sim[i_plot],col=col_year)

      sm_j<-t(apply(sm,1,function(x)rapply(split(x,j_sim),mean)))[,reorder_j]
      plot(d_sim[1:365],sm_j[1:365],ylim=c(0,max(sm_j)),type='n',
        main=paste('Mean soil moisture\n',wp_str),ylab='[mm]',xlab='')
      apply(sm_j,1,lines,x=d_sim[1:365],col=col_ann)

      # ET
      plot(d_sim[i_plot],et[1,i_plot],type='n',ylim=c(0,max(et[,i_plot])),
          main=paste('Evapotranspiration\n',wy_str),ylab='[mm/day]',xlab='')
      apply(et[,i_plot],1,lines,x=d_sim[i_plot],col=col_year)

      et_j<-t(apply(et,1,function(x)rapply(split(x,j_sim),mean)))[,reorder_j]
      plot(d_sim[1:365],et_j[1:365],ylim=c(0,max(et_j)),type='n',
        main=paste('Mean evapotranspiration\n',wp_str),ylab='[mm/day]',xlab='')
      apply(et_j,1,lines,x=d_sim[1:365],col=col_ann)

    dev.off()
  }
}

#legend('topleft',c(fuse_models,'uncalibrated','SCE_calibrated'),col=c(col_900,col_901,col_902,'black','black'),pch=c(15,15,15,16,8),bg='white')

#plot(ecdf_nse_sce_902_900,col='white',xlab='NSE',main='NSE difference over calibration period',xlim=c(-1,1))
#polygon(x=c(-0.1,0.1,0.1,-0.1),y=c(-2,-2,2,2),col='gray90',border=NA)
#lines(ecdf_nse_sce_902_900,col='darkorchid1')
#lines(ecdf_nse_sce_902_901,col='cadetblue3')
#abline(v=seq(-1.2,1.2,0.2),h=seq(-1.2,1.2,0.2),lty=3,lwd=0.5)

#legend('topleft',c('VIC - HMS','VIC - VIC-nosnow'),col=c('darkorchid1','cadetblue3'),pch=16,bg='white')

#dev.off()
