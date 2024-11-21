#!/bin/bash

#SBATCH -J WW3_wc
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=48
#SBATCH --mem=0
#SBATCH --account=def-gemmrich
#SBATCH --time 4-12:00:00 #For a 2 month run
#SBATCH --mail-user=name@email.com
#SBATCH --mail-type=END


# Script to run WW3 model, either a 6h forecast or 48h forecast

# set for a 6 hour or 48 hour forecast
forecast=6H
#forecast=48H

# path to model executables
# $HOME
PATHEXE="/home/beckyb/projects/def-gemmrich/beckyb/Coastal_ww3/WW3_with_currents/WW3/model/exe"
# path to boundary and wind files, where there is a directory called bound and wind
PATHIN="/home/beckyb/projects/def-gemmrich/beckyb/Coastal_ww3/ww3_input"
# /home/beckyb/projects/def-jklymak/beckyb/RC_ww3/WW3/work/input
module load StdEnv/2020
module load netcdf-fortran-mpi/4.5.2
module load nco
export PATH=$PATH:/home/beckyb/projects/def-gemmrich/beckyb/Coastal_ww3/WW3_with_currents/WW3/model/bin:/home/beckyb/projects/def-gemmrich/beckyb/Coastal_ww3/WW3_with_currents/WW3/model/exe
export WWATCH3_NETCDF=NC4
export NETCDF_CONFIG=$(which nc-config)

mkdir -p output_files restart_files

# Create mod_def.ww3 file for grid (only need to run when changes are made to switches or namelist.nml)
"$PATHEXE"/ww3_grid > out_ww3_grid

# Get dates in run_dates to run model
readarray -t dates < ./run_dates
echo "DATE = " $dates
tn=${#dates[@]}
if [ "$forecast" == "6H" ]; then
  STOP=$((tn-1))  #was tn-3
elif [ "$forecast" == "48H" ]; then
  STOP=$((tn-9))
fi

# iteration over run_dates
for ((i=0; i<=$STOP; i++)); do
echo "Start processing ${dates[i]}"

# Get boundary input for 00H and 12H start date
STR1="000000"
STR2="120000"
if [ "${dates[i]:9:6}" == "$STR1" ] || [ "${dates[i]:9:6}" == "$STR2" ]; then
  rm nest.ww3
  ln -s $PATHIN/bound/${dates[i]:0:8}${dates[i]:9:2}_nest_nep5km.ww3 nest.ww3  # link to nest.ww3
  echo "Boundary input file: "${dates[i]:0:8}${dates[i]:9:2}_nest_nep5km.ww3
fi

# Write model  nml files
start=${dates[i]}
if [ "$forecast" == "6H" ]; then
  end=${dates[i+1]}
elif [ "$forecast" == "48H" ]; then
  end=${dates[i+8]}
fi
rstrt_start=${dates[i+1]}
rstrt_end=${dates[i+2]}
rm ww3_prnc.nml

. write_shel.sh "$start" "$end" "$rstrt_start" "$rstrt_end"
. write_prnc_cur.sh "$start" "$end" #Testing prnc.inp for both currents and winds
. write_ounp.sh "$start" spec
. write_ounp.sh "$start" part
. write_ounf.sh "$start"
#. write_inp_cur.sh "$start" #Write the input for currents first

# Current forcing
cp $PATHIN/currents/${dates[i]:0:8}${dates[i]:9:2}_cur.nc ./${dates[i]:0:8}${dates[i]:9:2}_cur.nc
echo "Current input file: "${dates[i]:0:8}${dates[i]:9:2}_cur.nc
"$PATHEXE"/ww3_prnc > out_ww3_prnc_cur
rm ${dates[i]:0:8}${dates[i]:9:2}_cur.nc
rm ww3_prnc.nml #Clear the nml file then write to it for winds. They cannot be read at the same time.

. write_prnc.sh "$start" "$end"
# Wind forcing
cp $PATHIN/wind/${dates[i]:0:8}${dates[i]:9:2}.nc ./${dates[i]:0:8}${dates[i]:9:2}.nc
echo "Wind input file: "${dates[i]:0:8}${dates[i]:9:2}.nc
"$PATHEXE"/ww3_prnc > out_ww3_prnc_wnd
rm ${dates[i]:0:8}${dates[i]:9:2}.nc
#rm ww3_prnc.inp #Clear again for the next date

# Run model
mpirun -np 48 "$PATHEXE"/ww3_shel > out_ww3_shel_${dates[i]:0:8}${dates[i]:9:2}

# Post processing
"$PATHEXE"/ww3_ounf > out_ww3_ounf
mv ww3_ounp_spec.nml ww3_ounp.nml
"$PATHEXE"/ww3_ounp > out_ww3_ounp_spec
mv ww3_ounp_part.nml ww3_ounp.nml
"$PATHEXE"/ww3_ounp > out_ww3_ounp_part

echo "end processing ${dates[i]}"

# save model output and restart file
mv log.ww3 log.ww3_${dates[i]:0:8}${dates[i]:9:2}
# point output
mv *_spec.nc output_files/ww3.${dates[i]:0:8}${dates[i]:9:2}_spec.nc
mv *_tab.nc output_files/ww3.${dates[i]:0:8}${dates[i]:9:2}_tab.nc
# field output
mv *_hs.nc output_files/ww3.${dates[i]:0:8}${dates[i]:9:2}_hs.nc
mv *_dir.nc output_files/ww3.${dates[i]:0:8}${dates[i]:9:2}_dir.nc
mv *_fp.nc output_files/ww3.${dates[i]:0:8}${dates[i]:9:2}_fp.nc
mv *_hig.nc output_files/ww3.${dates[i]:0:8}${dates[i]:9:2}_hig.nc
mv *_wnd.nc output_files/ww3.${dates[i]:0:8}${dates[i]:9:2}_wnd.nc
mv *_cur.nc output_files/ww3.${dates[i]:0:8}${dates[i]:9:2}_cur.nc
# restart file
cp restart001.ww3  restart_files/restart_${dates[i+1]:0:8}${dates[i+1]:9:2}.ww3
mv restart001.ww3 restart.ww3

done

echo finished
