rm(list=ls())

load('/Volumes/d1/data/param_transfer/624.Rdata')

### PLOT NSE CDF

reg_mode<-data.frame(mode=c('sce_cal','sce_val','best','all','dist_3','dist_10','clim_3','clim_10'),
                     col=c('gold','blue','brown','green','pink','red','purple','darkorchid2'))

reg_mode<-reg_mode[-c(5,7),]

reg_mode$mode<-as.character(reg_mode$mode)
reg_mode$col<-as.character(reg_mode$col)

for (p in 1:dim(reg_mode)[1]){
  
  pdf(paste0('/Volumes/d1/plots/param_transfer/NSE_CDF_reg_mode_loc',p,'.pdf'),width = 6,height=6,useDingbats = FALSE)
  
  plot(0,0,xlab='NSE',xlim=c(0.2,1),ylim=c(0,1),'n',ylab='F(x)',
       main=paste('NSE cumulative distribution function for',sum(!is.na(nse[['sce_cal']])),'basins'))
  
  par(mar=c(4,4,2,0.5))
  
  for(m in 1:p){
    
    my_ecdf<-ecdf(nse[[reg_mode$mode[m]]])
    lines(my_ecdf,col=reg_mode$col[m],lty=2)
    
  }
  
  abline(v=seq(0.1,1,0.2),h=seq(0.1,1,0.2),lty=3,lwd=0.5)
  
  legend('topleft',reg_mode$mode[1:p],col=reg_mode$col[1:p],lwd=2)
  
  dev.off()
  
}
