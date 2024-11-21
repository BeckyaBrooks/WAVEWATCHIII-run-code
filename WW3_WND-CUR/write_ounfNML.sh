#!/bin/bash

#write_ounf.sh: writes ww3_ounf.nml file
#              input start date of the model and can edit params variable for field output parameters
#              Execute . "$start"
params="HS DIR FP HIG WND CUR" #Added parameter for currents

if [[ $# -ne 1 ]]; then
 echo "Two parameters expected, $# given"
 exit 1
fi

fileName=ww3_ounf.nml
start=$1

echo "! -------------------------------------------------------------------- !" > $fileName
echo "! WAVEWATCH III - ww3_ounf.nml - Grid output post-processing            !" >> $fileName
echo "! -------------------------------------------------------------------- !" >> $fileName

echo "&FIELD_NML" >> $fileName
printf '\tFIELD%%TIMESTART  =  '"'"'%s'"'"'\n\tFIELD%%TIMESPLIT = 4\n\tFIELD%%TIMESTRIDE = '"'"'3600'"'"'\n\tFIELD%%LIST = '"'"'%s'"'"'\n\tFIELD%%SAMEFILE = F\n\tFIELD%%TYPE = 4\n/\n\n' "$start" "$params" >> $fileName

echo "&FILE_NML" >> $fileName
printf '\tFILE%%NETCDF  =  4\n/\n\n' >> $fileName

echo "! -------------------------------------------------------------------- !" >> $fileName
echo "! WAVEWATCH III - end of namelist                                      !" >> $fileName
echo "! -------------------------------------------------------------------- !" >> $fileName
