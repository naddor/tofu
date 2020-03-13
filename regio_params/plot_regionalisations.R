rm(list=ls())

# SET GENERIC PATHS
hostname<-system('hostname',intern=TRUE)

if(hostname=='hydro-c1'){

  source('/home/naddor/scripts/r_scripts/tofu/set_default_paths.R')  # set all paths

} else {

  source('/glade/u/home/naddor/scripts/r_scripts/tofu/set_default_paths.R')  # set all paths
  source('/glade/u/home/naddor/scripts/r_scripts/tofu/set_camels_paths.R')

}

fuse_id_list<-c('900','902','904')

### PLOT NSE AND HS CDF

cdf_line_width=1.5

pdf(paste0(dir_plots,'param_transfer_maurer/CDFs_reg_all.pdf'),width=7.5,height=9,useDingbats = FALSE)

  par(mfcol=c(5,3),mar=c(4,4,1,0.5))

  for(fuse_id in fuse_id_list){

    load(paste0('/glade/u/home/naddor/data/para_transfer_maurer/nse_hs_',fuse_id,'.Rdata'))

    # define colors here

    reg_mode<-data.frame(mode=c('all','best','clim_3','clim_10','dist_3','dist_10','sce_val','sce_cal'),
                         col=c('seashell4','orchid4','olivedrab2','olivedrab4','orangered3','orange1','cornflowerblue','dodgerblue4'))

    reg_mode$mode<-as.character(reg_mode$mode)
    reg_mode$col<-as.character(reg_mode$col)

    reg_mode_non_nse<-reg_mode[-2,]

    plot(0,0,xlab='NSE [-]',xlim=c(0.2,1),ylim=c(0,1),'n',ylab='F(x)')

    for(m in 1:dim(reg_mode)[1]){

      x<-sort(nse[[reg_mode$mode[m]]])
      lines(x, (1:length(x))/length(x),col=reg_mode$col[m],lwd=cdf_line_width)

    }

    abline(v=seq(0.1,1,0.2),h=seq(0.1,1,0.2),lty=3,lwd=0.5)

    # QMEAN

    plot(0,0,xlab='Relative error q_mean [-]',xlim=c(-0.4,0.4),ylim=c(0,1),'n',ylab='F(x)')

    for(m in 1:dim(reg_mode_non_nse)[1]){

      x<-sort(e_qmean[[reg_mode_non_nse$mode[m]]])
      lines(x, (1:length(x))/length(x),col=reg_mode$col[m],lwd=cdf_line_width)

    }

    abline(v=seq(-0.4,0.4,0.2),h=seq(0.1,1,0.2),lty=3,lwd=0.5)

    # BFI

    plot(0,0,xlab='Relative error baseflow index [-]',xlim=c(-0.4,0.4),ylim=c(0,1),'n',ylab='F(x)')

    for(m in 1:dim(reg_mode_non_nse)[1]){

      x<-sort(e_bfi[[reg_mode_non_nse$mode[m]]])
      lines(x, (1:length(x))/length(x),col=reg_mode$col[m],lwd=cdf_line_width)

    }

    abline(v=seq(-0.4,0.4,0.2),h=seq(0.1,1,0.2),lty=3,lwd=0.5)

    # SFDC

    plot(0,0,xlab='Relative error slope flow duration curve [-]',xlim=c(-0.4,0.4),ylim=c(0,1),'n',ylab='F(x)')

    for(m in 1:dim(reg_mode_non_nse)[1]){

      x<-sort(e_sfdc[[reg_mode_non_nse$mode[m]]])
      lines(x, (1:length(x))/length(x),col=reg_mode$col[m],lwd=cdf_line_width)

    }

    abline(v=seq(-0.4,0.4,0.2),h=seq(0.1,1,0.2),lty=3,lwd=0.5)

    plot.new()

  }

  legend('center',reg_mode$mode,col=reg_mode$col,lwd=2,ncol=2)

dev.off()


# Is the distance correlated to performance?

pdf(paste0(dir_plots,'CDFs_dist_',fuse_id,'.pdf'),width = 9,height=9,useDingbats = FALSE)

  par(mfcol=c(4,4),mar=c(4,4,2,0.5))

  for (my_exp in c('clim_3','clim_10','dist_3','dist_10')){

    plot(mean_hyd_diff[[my_exp]],nse[[my_exp]],ylim=c(0,1),main=my_exp,
        xlab='Mean hydrologic distance',ylab='NSE')
    legend('topright',paste('R2=',round(cor(mean_hyd_diff[[my_exp]],nse[[my_exp]],use='pairwise.complete.obs')^2,2)))

    plot(mean_hyd_diff[[my_exp]],e_qmean[[my_exp]],ylim=c(-1,1),
        xlab='Mean hydrologic distance',ylab='E_QMean')
    legend('topright',paste('R2=',round(cor(mean_hyd_diff[[my_exp]],e_qmean[[my_exp]],use='pairwise.complete.obs')^2,2)))

    plot(mean_hyd_diff[[my_exp]],e_bfi[[my_exp]],ylim=c(-1,1),
        xlab='Mean hydrologic distance',ylab='E_BFI')
    legend('topright',paste('R2=',round(cor(mean_hyd_diff[[my_exp]],e_bfi[[my_exp]],use='pairwise.complete.obs')^2,2)))

    plot(mean_hyd_diff[[my_exp]],e_sfdc[[my_exp]],ylim=c(-1,1),
        xlab='Mean hydrologic distance',ylab='E_SFDC')
    legend('topright',paste('R2=',round(cor(mean_hyd_diff[[my_exp]],e_sfdc[[my_exp]],use='pairwise.complete.obs')^2,2)))

  }

dev.off()
