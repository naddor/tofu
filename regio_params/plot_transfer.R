rm(list=ls())

fuse_id='900'
load(paste0('/gpfs/ts0/projects/Research_Project-CLES-00008/fuse_gmd/regio/nse_hs_',fuse_id,'with_def.Rdata'))

# define colors
reg_mode<-data.frame(mode=c('sce_cal','sce_val','best','all','dist_3','dist_10','clim_3','clim_10'),
                     col=c('gold','blue','brown','green','pink','red','purple','darkorchid2'))

reg_mode<-reg_mode[-c(5,7),]

reg_mode$mode<-as.character(reg_mode$mode)
reg_mode$col<-as.character(reg_mode$col)

# plot CDFs

pdf(paste0('~/plots/fuse_gmd/NSE_CDF_reg.pdf'),width = 6,height=6,useDingbats = FALSE)

  plot(0,0,xlab='NSE',xlim=c(0.2,1),ylim=c(0,1),'n',ylab='F(x)',
       main=paste('NSE cumulative distribution function for',sum(!is.na(nse[['sce_cal']])),'basins'))

  par(mar=c(4,4,2,0.5))

  for(m in 1:dim(reg_mode)[1]){

    my_ecdf<-ecdf(nse[[reg_mode$mode[m]]])
    lines(my_ecdf,col=reg_mode$col[m],lty=2)

  }

  abline(v=seq(0.1,1,0.2),h=seq(0.1,1,0.2),lty=3,lwd=0.5)

  legend('topleft',reg_mode$mode,col=reg_mode$col,lwd=2)

dev.off()
