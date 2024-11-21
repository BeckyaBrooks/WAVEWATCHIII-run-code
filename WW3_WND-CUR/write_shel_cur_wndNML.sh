#!/bin/bash

#write_shel.sh: writes ww3_shel.nml file
#              input start date and end date of the model, the restart start and end date, and can edit params variable for field output parameters
#              Execute with . write_shel.sh "$start" "$end" "$rstrt_start" "$rstrt_end"
params="HS DIR FP HIG HIG WND CUR"

if [[ $# -ne 4 ]]; then
 echo "Four parameters expected only $# given"
 exit 1
fi

start=$1
end=$2
rstart_start=$3
rstrt_end=$4

fileName=ww3_shel.nml

echo "! -------------------------------------------------------------------- !" > $fileName
echo "! WAVEWATCH III - ww3_shel.nml - single-grid model                     !" >> $fileName
echo "! -------------------------------------------------------------------- !" >> $fileName

echo "&DOMAIN_NML" >> $fileName
printf '\tDOMAIN%%START = '"'"'%s'"'"'\n\tDOMAIN%%STOP = '"'"'%s'"'"'\n/\n\n' "$start" "$end" >> $fileName

echo "&INPUT_NML" >> $fileName
printf '\tINPUT%%FORCING%%CURRENTS = '"'"'T'"'"'\n' >> $fileName
printf '\tINPUT%%FORCING%%WINDS = '"'"'T'"'"'\n/\n\n' >> $fileName

echo "&OUTPUT_TYPE_NML" >> $fileName
printf '\tTYPE%%FIELD%%LIST = '"'"'%s'"'"'\n\tTYPE%%POINT%%FILE = '"'"'./points.list'"'"'\n/\n\n' "$params" >> $fileName

echo "&OUTPUT_DATE_NML" >> $fileName
printf '\tDATE%%FIELD%%START = '"'"'%s'"'"'\n\tDATE%%FIELD%%STRIDE = '"'"'3600'"'"'\n\tDATE%%FIELD%%STOP = '"'"'%s'"'"'\n' "$start" "$end" >> $fileName
printf '\tDATE%%POINT%%START = '"'"'%s'"'"'\n\tDATE%%POINT%%STRIDE = '"'"'3600'"'"'\n\tDATE%%POINT%%STOP = '"'"'%s'"'"'\n' "$start" "$end" >> $fileName
printf '\tDATE%%RESTART%%START = '"'"'%s'"'"'\n\tDATE%%RESTART%%STRIDE = '"'"'3600'"'"'\n\tDATE%%RESTART%%STOP = '"'"'%s'"'"'\n/\n\n' "$rstrt_start" "$rstrt_end" >> $fileName

echo "! -------------------------------------------------------------------- !" >> $fileName
echo "! WAVEWATCH III - end of namelist                                      !" >> $fileName
echo "! -------------------------------------------------------------------- !" >> $fileName
