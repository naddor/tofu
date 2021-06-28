# load env
source activate fuse_env

# stitch bands - note: this will add a "calendar" attribute to the time variable
python -c 'import xarray as xr; xr.open_mfdataset("*runs*00*",combine="by_coords").to_netcdf("combined_run.nc")'
