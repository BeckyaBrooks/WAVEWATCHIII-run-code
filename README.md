## In this repository you will find:
1. Shell scripts
2. Python

\
Shell scripts are used for running WW3, and Python is used for analysis. Code is available for running the model with just winds, and with winds and currents. In the directory where the model is running, all files with "write" prefix must be present, along with the model grid file, a list of dates to run the model for, a list of coordinates for point output, and namelists.nml. The model will generate the necessary .nml files in preprocessing, and the mod_def.ww3 for the first time the model is run with a grid. A successful model run will generate a log.ww3, nest.ww3, restart.ww3, wind.ww3, and current.ww3 if using currents. The log.ww3 file will contain information on what fields were correctly prescribed. 
