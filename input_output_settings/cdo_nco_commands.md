This file contains examples of cdo and nco commands (in no specific order) that can be used to produce FUSE input files.

### Generic commands

* find period covered by a file:
```
cdo showyear file.nc
cdo showdate file.nc
```

### Disaggregate files

* extract data for a subdomain (longitudes from 120E to 90W and latitudes from 20N to 20S from all input fields):
```
cdo sellonlatbox,120,-90,20,-20 ifile ofile
```

* extract specific variables from a file containing multiple variables:
```
for ((y=1979;y<=1989;y++)); do
    ncks -v t_mean erai_gard_$y.nc  wrf50_erai_metsim_tas_$y.nc
    ncks -v pcp erai_gard_$y.nc  wrf50_erai_metsim_pr_$y.nc
done
```

* create files for specific years:
```
for ((y=1979;y<=1989;y++)); do
    cdo selyear,$y cesm1-cam5_rcp85_r1i1p1_pet.nc cesm1-cam5_rcp85_r1i1p1_$y.nc;
done
```

### Aggregate files

* concatenate files along time axis (they must already on the same grid):
```
cdo mergetime file_1990.nc file_1991.nc file_1990-1991.nc
```

* combine files for different variables (already on the same grid):
```
for ((y=1979;y<=1989;y++)); do
  cdo merge wrf50_erai_metsim_pet_$y.nc wrf50_erai_metsim_tas_$y.nc wrf50_erai_metsim_pr_$y.nc wrf50_erai_metsim_allvars_$y.nc;
done
```

### Change metadata

* change missing value - the 4th argument must be either f or d (float or double) depending on the kind of the variable:
```
#ncatted -O -a _FillValue,pr,o,f,-9999. $my_file
#ncatted -O -a missing_value,pr,o,f,-9999. $my_file
```

* rename variables and change units:
```
for ((y=1979;y<=1989;y++)); do

  my_file=wrf50_erai_metsim_allvars_$y.nc

  # rename variables
  ncrename -O -v t_mean,temp $my_file $my_file
  ncrename -O -v pcp,pr $my_file $my_file
  ncrename -O -v lon,longitude $my_file $my_file
  ncrename -O -v lat,latitude $my_file $my_file

  # change units
  ncatted -O -a units,pr,m,c,"mm/day” $my_file $my_file
  ncatted -O -a units,pet,m,c,"mm/day” $my_file $my_file

done
```

### Regridding

Perform bilinear interpolation:
```
cdo griddes CN05.1_Pre_1961_2017_daily_025x025.nc> grid_CN051.txt  #creates grid description from a pre-existing file
cdo remapbil,grid_CN051.txt file.nc interpolated_file.nc # use this description to perform interpolation
```

### Split and recombine a domain (see [cdo doc](https://code.mpimet.mpg.de/projects/cdo/embedded/index.html#x1-1340002.2.12)) 
```
cdo distgrid,nx[,ny]  infile obase
cdo collgrid infile[1-6] outfile
```
