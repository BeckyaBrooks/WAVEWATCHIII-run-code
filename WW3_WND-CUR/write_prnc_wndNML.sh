#!/bin/bash

# write_prnc.sh: writes ww3_prnc.nml file
#                input start date and end date of the model
#                Execute with . write_prnc.sh "$start" "$end"

if [[ $# -ne 2 ]]; then
 echo "Two parameters expected, $# given"
 exit 1
fi

start=$1
end=$2
rstart_start=$3
rstrt_end=$4

fileName=ww3_prnc.nml

echo "! -------------------------------------------------------------------- !" >> $fileName
echo "! WAVEWATCH III - ww3_prnc.nml - Field preprocessor                    !" >> $fileName
echo "! -------------------------------------------------------------------- !" >> $fileName

echo "&FORCING_NML" >> $fileName
printf '\tFORCING%%TIMESTART  =  '"'"'%s'"'"'\n\tFORCING%%TIMESTOP = '"'"'%s'"'"'\n' "$start" "$end" >> $fileName
printf '\tFORCING%%FIELD%%WINDS = t\n\tFORCING%%GRID%%ASIS = f\n\tFORCING%%GRID%%LATLON = t\n/\n\n' >> $fileName

echo "&FILE_NML" >> $fileName
printf '\tFILE%%FILENAME  =  '"'"'./%s.nc'"'"'\n\tFILE%%LONGITUDE = '"'"'longitude'"'"'\n\tFILE%%LATITUDE = '"'"'latitude'"'"'\n\tFILE%%VAR(1) = '"'"'U'"'"'\n\tFILE%%VAR(2) = '"'"'V'"'"'\n\tFILE%%TIMESHIFT = '"'"'%s'"'"'\n/\n\n' "${start:0:8}${start:9:2}" "$start" >> $fileName

echo "! -------------------------------------------------------------------- !" >> $fileName
echo "! WAVEWATCH III - end of namelist                                      !" >> $fileName
echo "! -------------------------------------------------------------------- !" >> $fileName
