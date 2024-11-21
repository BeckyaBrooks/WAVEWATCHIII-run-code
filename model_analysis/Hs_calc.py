import xarray as xr
import numpy as np
#Get the 1d spectra for each time and station
def to1Dspectrum(efth):
    """
    Calculates the 1D wave energy density spectrum
    for a given 2D wave energy density spectrum. 
    Integrates along the directional axis, to make
    it only a function of frequency.
    """
    ef = np.trapz(efth,dx=2*np.pi/36,axis=1)
    return ef
def passiton(efth,stn):
    """
    Here to pass individual 2D-spectra to a separate 
    function.
    """
    Sf = [] 
    for i in range(len(efth[:])):
        Sf.append(to1Dspectrum(efth[i][stn][:][:]))
        
    return Sf

def spectralMoment(Sf,f,start,stop,n):
    """
    Calculates the spectral moment of the spectral density,
    which is calculated along the first axis of the input array.
    This function calls another which integrates first along
    the time axis for a given input range.
    Returns a 1D-array representing the moment at each station.
    """
    m_n = np.trapz(Sf*f[start:stop]**n,f[start:stop])
    
    return m_n



#Load model data:
all_spec = xr.open_mfdataset("file_path/ww3.2023*.nc",concat_dim="time",combine='nested')

#Extract components for calculating significant wave height from spectral point output
efth_ar = all_spec['efth'].values
stn = all_spec['station'].values
fq = all_spec['frequency'].values
mod_time = all_spec['time'].values

all_Sf_mod=[]
for stn in range(stn):
    all_Sf_mod.append(passiton(efth_ar,stn))
#Adjustable frequency range, to experiment with model response in limiting
#range of spectral output. There could be an ideal range for which model
#data is closer in estimate to observations.

fs = 0
fe = None
m0 = []

for i in range(len(all_Sf_mod[:])):
        m0.append(spectralMoment(all_Sf_mod[i][fs:fe],fq,fs,fe,0))

#Calculate model significant wave height for all stations:
hs_mod =[]
for i in range(len(m0)):
    hs_mod.append(4*np.sqrt(m0[i]))
