# (C) 2020 Nele Reyniers, University of East Anglia
# Code used for the creation of potential evaporation datasets for the SWARM project.
#
# Contact: N.Reyniers@uea.ac.uk

from pathlib import Path
import sys
from datetime import datetime
from optparse import OptionParser

import xarray as xr
import numpy as np


def rolldoy(da):
    """
    rolling mean of 10 time steps for given xr.DataArray.
    if the da supplied contains the same day of year over different times, this contains the 10y mean of tas at this doy.
    """
    return da.rolling(time=10, min_periods=1, center=True).construct('window').mean('window')


def rolling_doy_mean(da):
    """
    Computes the rolling mean of 10 years for each day of year separately.
    :param da: xr.DataArray with daily temperature data
    :return : rolling mean of 10 years for each day of year separately.
    """
    return da.groupby('time.dayofyear').map(rolldoy, shortcut=False)


def oudin(da_tas, da_re, K1=100, K2=5, lambda_lhf=2.45, rho_w=1000, evpotvarname='evpot-oudin'):
    """
    inputs
    ------
    da_tas: data array daily average temperature [degC]
    da_re: data array extraterrestrial radiation [MJ m-2 day-1]
    lambda_lhf [MJ kg-1]: latent heat flux
    rho_w [kg m-3]: density of water

    return
    ------
    xr.Dataset containing pe

    reference
    ---------
    Oudin, L., Hervieu, F., Michel, C., Perrin, C., Andréassian, V., Anctil, F., & Loumagne, C. (2005). Which
     potential evapotranspiration input for a lumped rainfall–runoff model?: Part 2—Towards a simple and efficient
     potential evapotranspiration model for rainfall–runoff modelling. Journal of hydrology, 303(1-4), 290-306. Eq (3)
    """
    da_pe = da_re / (lambda_lhf * rho_w) * (da_tas + K2)/K1  # Eq 3 in general form
    print(da_pe)
    da_pe = da_pe.to_dataset(name=evpotvarname)
    da_pe[evpotvarname] = xr.where(da_tas + K2 < 0, 0, da_pe[evpotvarname])  # "otherwise"
    new_attrs = {'pe_calculation_method': 'Oudin et al., 2005 (Equations 2,3)',
                 'reference': \
                 'Oudin, L., Hervieu, F., Michel, C., Perrin, C., Andréassian, V., Anctil, F., & Loumagne,'\
                 + ' C. (2005). Which potential evapotranspiration input for a lumped rainfall–runoff model?:'\
                 + ' Part 2—Towards a simple and efficient potential evapotranspiration model for rainfall–runoff '\
                 + 'modelling. Journal of hydrology, 303(1-4), 290-306.',
                 'K1': K1,
                 'K2': K2,
                 'unit': 'mm day-1'}
    da_pe[evpotvarname] = da_pe[evpotvarname].assign_attrs(new_attrs)
    return da_pe


def extraterrestrial_radiation(lat, doy):
    """
    Calculate extraterrestrial radiation as input into the Oudin PE formulation.
    Depends on day of year and latitude (both xr.DataArrays).

    returns
    ------
    da_re: data array extraterrestrial radiation [MJ m-2 day-1]

    """
    lat_rad = lat / 180 * np.pi  # rad
    I_sc = 4921  # kJ m-2 hr solar constant
    E_o = 1 + 0.033 * np.cos(2 * np.pi * doy / 365)  # eccentricity correction factor
    delta = 0.4093 * np.sin(2 * np.pi * (doy + 284) / 365)
    w_s = np.arccos(-np.tan(lat_rad) * np.tan(delta))

    assert w_s.shape == (lat_rad.shape[0], doy.shape[0])
    w_s = w_s.where(np.tan(lat_rad) * np.tan(delta) <= 1, np.pi)
    w_s = w_s.where(np.tan(lat_rad) * np.tan(delta) >= -1, 0)

    da_re = 24 / np.pi * I_sc * E_o * (w_s * np.sin(delta) * np.sin(lat_rad) +
                                       np.cos(delta * np.cos(lat_rad) * np.sin(w_s)))
    return da_re


def main():
    # parse input
    parser = OptionParser()
    parser.add_option('-d', '--daily-tas', action='store',
                      type='string', dest='path_input_daily_tas', default='',
                      help=('Path to the input daily average temperature file. This file is \
                      also supposed to contain latitude in degrees and time in a format that allows \
                      the .dt.dayofyear method.'))
    parser.add_option('-l', '--longterm-tas', action='store',
                      type='string', dest='path_input_longterm_tas', default='',
                      help=('Path to long term average tas file. This file is \
                      also supposed to contain latitude in degrees and time in a format that allows \
                      the .dt.dayofyear method.'))
    parser.add_option('-v', '--tas-variable-name', action='store',
                      type='string', dest='var_t', default='',
                      help=('Name under which the temperature variable is stored'))
    parser.add_option('-t', '--output-longterm-tas', action='store',
                      type='string', dest='path_output_longterm_tas', default='',
                      help=('Path to where the intermediate result long term tas dataset should be written.'))
    parser.add_option('-o', '--output-pe', action='store',
                      type='string', dest='path_output_pe', default='',
                      help=('Path to where the resulting PE dataset should be written.'))
    parser.add_option('-s', '--save-longterm-tas', action='store_true',
                      dest='save_longterm_tas', default=False,
                      help=('Whether to write long term tas intermediate product to file. Default: don\'t.'))
    (options, args) = parser.parse_args()  # elements in options can be accessed with .element
    print(options)  # hpc

    path_input_daily_tas = options.path_input_daily_tas
    path_input_longterm_tas = options.path_input_longterm_tas
    path_output_longterm_tas = options.path_output_longterm_tas
    path_output_pe = options.path_output_pe
    var_t = options.var_t

    assert Path(path_output_pe[:path_output_pe.rfind('/')]).is_dir(), \
        "pe output file location {} is not a directory"

    # compute or read long term daily average temperaure
    if len(path_input_longterm_tas) > 0:
        assert Path(path_input_longterm_tas).exists(),\
            "longterm tas input file {} does not exist"
        da_tas_rolling_doy_mean = xr.open_dataset(path_input_longterm_tas, chunks={'lon': 5, 'lat': 5})
        da_tas_rolling_doy_mean = da_tas_rolling_doy_mean[var_t]
    elif (len(path_input_daily_tas) > 0) & (len(path_output_longterm_tas) > 0):
        assert Path(path_input_daily_tas).exists(),\
            "daily tas input file {} does not exist"
        assert Path(path_output_longterm_tas[:path_output_longterm_tas.rfind('/')]).is_dir(), \
            "long term tas output file location {} is not a directory"
        ds_daily_tas = xr.open_dataset(path_input_daily_tas, chunks={'lon': 5, 'lat': 5})
        da_tas_rolling_doy_mean = rolling_doy_mean(ds_daily_tas[var_t])
        da_tas_rolling_doy_mean.name = var_t
        if options.save_longterm_tas:
            da_tas_rolling_doy_mean.to_netcdf(path_output_longterm_tas)
    else:
        raise Exception('Provide either a daily or a longterm tas input.')

    # calculate extraterrestrial rad
    da_re = extraterrestrial_radiation(da_tas_rolling_doy_mean.lat, da_tas_rolling_doy_mean.time.dt.dayofyear)

    # calculate PE
    ds_pe_oudin = oudin(da_tas_rolling_doy_mean, da_re, evpotvarname='pet-oudin')

    # add some metadata and write to file
    global_attrs = {
        'daily tas source': path_input_daily_tas,
        'long term tas file': path_input_longterm_tas + path_output_longterm_tas if options.save_longterm_tas else 'not saved',
        'long term tas strategy': 'rolling 10y mean for every DOY',
        'creation script': sys.argv[0] + ' (N. Reyniers)',
        'creation time': datetime.now().strftime('%H:%M %d %B %Y'),
        'creator': 'N. Reyniers (N.Reyniers@uea.ac.uk, University of East Anglia)'
    }
    ds_pe_oudin = ds_pe_oudin.assign_attrs(global_attrs)
    ds_pe_oudin.to_netcdf(path_output_pe, format='NETCDF4', encoding={'pet-oudin': {"dtype": "float32"}})


if __name__ == "__main__":
    main()
