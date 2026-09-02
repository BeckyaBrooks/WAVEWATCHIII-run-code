import numpy as np
from scipy.stats import pearsonr
from scipy.interpolate import interp1d
from scipy.interpolate import splrep
from datetime import timedelta
from datetime import datetime

def toNameString(byte_name):
    """
    Takes in a byte object representing
    the station names, joins the individual indices 
    into one array, and is then converted to a string.
    """
    
    join_name = b''.join(byte_name)
    str_name = join_name.decode("utf-8") 
    
    return str_name

def datenum_to_datetime(datenum):
    """
    Convert Matlab datenum into Python datetime.
    :param datenum: Date in datenum format
    :return:        Datetime object corresponding to datenum.
    From: https://gist.github.com/victorkristof/b9d794fe1ed12e708b9d
    """
    days = datenum % 1
    hours = days % 1 * 24
    minutes = hours % 1 * 60
    seconds = minutes % 1 * 60
    milliseconds = seconds % 1 *1000
    return datetime.fromordinal(int(datenum)) \
           + timedelta(days=int(days)) \
           + timedelta(hours=int(hours)) \
           + timedelta(minutes=int(minutes)) \
           + timedelta(seconds=int(seconds)) \
           + timedelta(milliseconds = round(milliseconds))\
           - timedelta(days=366)


def str_to_int(ModdateArr,buoyDateArr):
    """
    Converts string time into numpy time so that the time
    shared between the buoy and model is common, and 
    interpolation is more straightforward.
    """
    Modint_arr =[]
    buoyIntArr = []
    buoydt64 = np.array(buoyDateArr,dtype='datetime64[ns]')
    
    for i in range(len(ModdateArr)):
        Modint_arr.append(int(ModdateArr[i]))
    for i in range(len(buoyDateArr)):
        buoyIntArr.append(int(buoydt64[i]))
        
    return np.array(Modint_arr),np.array(buoyIntArr)


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

def find_fp(sf, fq_bins):
    """
    Finds the peak frequency for each station and time.
    
    Parameters:
        spectrum (np.ndarray): 3D array of shape (station, time, frequency).
        frequency_bins (np.ndarray): 1D array of frequency values.
    
    Returns:
        peak_frequencies (np.ndarray): 2D array of peak frequencies with shape (station, time).
    """
    # Find the index of the maximum energy along the frequency dimension (axis=2)
    max_index = np.argmax(sf, axis=2)  # Shape: (station, time)
    
    # Use indices from argmax to extract the corresponding frequency values
    pfs = fq_bins[max_index]
    
    return pfs

def all_CTCC(Sf,f,f_subs):
    m0,m1 = [], []
    T01,tau = [], []
    rho,lmda = [], []
    r = []
    #Sf is 1D, as is f. f_subs is 666 by 36.
    if f_subs==None: #None for buoy array, since the case could be only \
                        #comparing against the model subsets for the full buoy range only
        fs = 4
        fe = None
        for i in range(len(Sf[:])):
        
            m0.append(spectralMoment(Sf[i][fs:fe],f,fs,fe,0))
            m1.append(spectralMoment(Sf[i][fs:fe],f,fs,fe,1))
        
            T01.append(m0[i]/m1[i])
            if np.isnan(T01[i]):
                T01[i]=0
            #PArt 1
            tau.append(T01[i]/2)
        
            rho.append(np.trapz(Sf[i][fs:fe]*np.cos(2*np.pi*np.asarray(f[fs:fe])*np.asarray(tau[i])),f[fs:fe]))
            lmda.append(np.trapz(Sf[i][fs:fe]*np.sin(2*np.pi*np.asarray(f[fs:fe])*np.asarray(tau[i])),f[fs:fe]))
        
            r.append((1/m0[i])*np.sqrt(rho[i]**2+lmda[i]**2))
            if np.isnan(r[i]):
                r[i]=0
         
        return r
    
    elif f_subs!=None:
    
        for i in range(len(f_subs[:])): #number of subsets to go through
            #finds min and max frequency
            fs=list(np.where(f==f_subs[i][0]))[0][0]
            fe=list(np.where(f==max(f_subs[i])))[0][0]
            if fe==len(f):
                fe=None
            m0.append(spectralMoment(Sf[fs:fe],f,fs,fe,0))
            m1.append(spectralMoment(Sf[fs:fe],f,fs,fe,1))
        
            T01.append(m0[i]/m1[i])
            if np.isnan(T01[i]):
                T01[i]=0
            tau.append(T01[i]/2)
            #PArt 2
            rho.append(np.trapz(Sf[fs:fe]*np.cos(2*np.pi*np.asarray(f[fs:fe])*np.asarray(tau[i])),f[fs:fe]))
            lmda.append(np.trapz(Sf[fs:fe]*np.sin(2*np.pi*np.asarray(f[fs:fe])*np.asarray(tau[i])),f[fs:fe]))
        
            r.append((1/m0[i])*np.sqrt(rho[i]**2+lmda[i]**2))
            if np.isnan(r[i]):
                r[i]=0
    
        return r
    
def ScatterIndex(mod,obs):
    """
    Calculates the root mean squared deviation divided by the 
    mean. The percentage RMS difference WRT the mean of the 
    observations.
    """
    N = len(obs)
    M_O_sub =[]
    obs_avg = np.mean(obs)
    for i in range(len(obs)):
        M_O_sub.append((mod[i]-obs[i])**2)
    
    SI = (np.sqrt((1/N)*sum(M_O_sub))/obs_avg)*100
    
    return SI

def Bias(mod,obs):
    """
    Calculates the difference between the estimated value
    and the true value (modeled vs observed)
    """
    N = len(obs)
    b_i=[]
    
    for i in range(len(obs)):
        b_i.append(mod[i]-obs[i])
        
    bias = (1/N)*sum(b_i)
    
    return bias

def Correlation_Coeff(mod,obs):
    """
    Calculates the correlation coefficient using
    Scipy.stats pearsonr function, which determines
    linear correlation. Was checked against for loop
    and sum (manual) method, and returns the same values.
    """
    #R = pearsonr(mod,obs)[0]
    r_top=[]
    r_botm=[]
    r_boto=[]
    for i in range(len(mod)):
        r_top.append((mod[i]-np.mean(mod))*(obs[i]-np.mean(obs)))
        r_botm.append((mod[i]-np.mean(mod))**2)
        r_boto.append((obs[i]-np.mean(obs))**2)
        
    R = sum(r_top)/(np.sqrt(sum(r_botm)*sum(r_boto)))
    
    return R

def slope(rM,rB):
    """
    Calculates the line of best fit-minimizes
    the distance from each y point to each x point
    """
    m,b = np.polyfit(rB,rM,1)
    return m,b


def TimeDiff(t_mod,t_buoy,mod_dat,buoy_dat):
    """
    Interpolate within function and then compare two time arrays of 
    same size. If the time values occur within 30 min, then keep
    the data corresponding to those indices. Interpolate to the 
    smaller array. All interpolations occur within this function,
    so the condition will handle the different sized arrays and return
    only the relevant data.
    """
    mod_val = []
    buoy_val = []
    time_val = []
    hour = t_mod[1]-t_mod[0]
    half_hr = hour/2
    
    
    if len(t_mod)>len(t_buoy): #-> interpolate model to the buoy array size
        #use the larger time array twice in interp1d and use nearest neighbour
        t_interp = interp1d(t_mod,t_mod,fill_value="extrapolate",kind="nearest-up")(t_buoy) #gives same size as buoy array
        rM_interp = interp1d(t_mod,mod_dat,fill_value="extrapolate")(t_interp)
    #return rM_interp
        
        for i in range(len(t_interp)):
            if abs(t_interp[i]-t_buoy[i])<half_hr:# and ~np.isnan(buoy_dat[i]) and buoy_dat[i]<1 and rM_interp[i]<1:#
                mod_val.append(rM_interp[i])
                buoy_val.append(buoy_dat[i])
                time_val.append(t_interp[i])
                
        return mod_val,buoy_val,time_val

    elif len(t_mod)<len(t_buoy): #-> interpolate buoy to model array size
        t_interp = interp1d(t_buoy,t_buoy,fill_value="extrapolate",kind="nearest")(t_mod)
        rB_interp = interp1d(t_buoy,buoy_dat,fill_value="extrapolate")(t_interp)
        
        # Get times that occur within 30 minutes
        for i in range(len(t_interp)):
            if abs(t_interp[i]-t_mod[i])<half_hr:# and ~np.isnan(rB_interp[i]) and rB_interp[i]<1 and mod_dat[i]<1:
                mod_val.append(mod_dat[i])
                buoy_val.append(rB_interp[i])
                time_val.append(t_interp[i])
        
                
        return mod_val,buoy_val,time_val
    
def arr2mat(in_arr):
    dat_mat = np.zeros((35,70))
    arr_i = 0
    col_j=0
    for i in range(0,35):
        col_j=(i-1)*2
        for j in range(i,35):
            #print(i,col_j)
            #print(col_j)
            col_j+=1
            dat_mat[i][col_j] = in_arr[arr_i]
            arr_i +=1
    
    return dat_mat