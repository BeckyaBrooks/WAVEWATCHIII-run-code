#!/bin/bash

#write_ounp.sh: writes ww3_ounp.nml file for either the spectral output (file ww3_ounp_spec.nml) or partitioned output (file ww3_ounp_part.nml)
#              Note: ww3_ounp_spec.nml and ww3_ounp_part.nml are renamed to ww3_ounp.nml in run_model.sh to be properly run
#              input start date of the model and either spec or part
#              Execute . write_ounp.sh "$start" spec and . write_ounp.sh "$start" part
#Same file for running the model both with and without currents

if [[ $# -ne 2 ]]; then
 echo "Two parameters expected, $# given"
 exit 1
fi

start=$1
spec_type=$2

if [ "$spec_type" == "spec" ]; then
  fileName=ww3_ounp_spec.nml
  output=3
fi
if [ "$spec_type" == "part" ]; then
  fileName=ww3_ounp_part.nml
  output=4
fi

echo "! -------------------------------------------------------------------- !" > $fileName
echo "! WAVEWATCH III - ww3_ounp.nml - Point output post-processing          !" >> $fileName
echo "! -------------------------------------------------------------------- !" >> $fileName

echo "&POINT_NML" >> $fileName
printf '\tPOINT%%TIMESTART  =  '"'"'%s'"'"'\n\tPOINT%%TIMESPLIT = 4\n\tPOINT%%TIMESTRIDE = '"'"'3600'"'"'\n\tPOINT%%TYPE = 1\n\tPOINT%%DIMORDER = T\n/\n\n' "$start" >> $fileName

echo "&FILE_NML" >> $fileName
printf '\tFILE%%NETCDF  =  4\n/\n\n' >> $fileName

echo "&SPECTRA_NML" >> $fileName
printf '\tSPECTRA%%OUTPUT  =  %s\n/\n\n' "$output" >>  $fileName

echo "! -------------------------------------------------------------------- !" >> $fileName
echo "! WAVEWATCH III - end of namelist                                      !" >> $fileName
echo "! -------------------------------------------------------------------- !" >> $fileName
