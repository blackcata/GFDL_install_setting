#!/bin/csh -f
# Minimal runscript for MOM experiments


#---------------------------------------------------------------------------------------
# Basic setup for MOM experiment - GCM type, experiment name, compile type, CPU number
set type          = MOM_solo       # type of the experiment
set name          = box1
set platform      = gfortran     # A unique identifier for your platform
set npes          = 8            # number of processor
                                 # Note: If you change npes you may need to change
                                 # the layout in the corresponding namelist
#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# KDH-Loop, KM.Noh 2019 
# Loop system for each year
set StartYear     = 1     #KDH-Loop
set RestartYear   = 1941
set EndYear       = 1941  #KDH-Loop
#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# Options for experiments
set valid_npes = 0
set help = 0
set download = 0
set debug = 0
set valgrind = 0

set argv = (`getopt -u -o h -l type: -l platform: -l npes: -l experiment: -l  \
             startyear: -l restartyear: -l endyear: -l  \
             debug -l valgrind -l help -l download_input_data --  $*`)

while ("$argv[1]" != "--")
    switch ($argv[1])
        case --type:
                set type = $argv[2];        shift argv; breaksw
        case --platform:
                set platform = $argv[2];    shift argv; breaksw
        case --npes:
                set npes = $argv[2];        shift argv; breaksw
        case --experiment:
                set name = $argv[2];        shift argv; breaksw
        case --startyear:
                set StartYear = $argv[2];   shift argv; breaksw
        case --restartyear:
                set RestartYear = $argv[2]; shift argv; breaksw
        case --endyear:
                set EndYear = $argv[2];     shift argv; breaksw
        case --debug:
                set debug = 1;     breaksw
        case --valgrind:
                set valgrind = 1;  breaksw
        case --help:
                set help = 1;      breaksw
        case -h:
                set help = 1;      breaksw
        case --download_input_data:
                set download = 1;  breaksw
    endsw
    shift argv
end
shift argv
#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# Help statemnets for MOM_run.csh
if ( $help ) then
    echo "The optional arguments are:"
    echo "--type       followed by the type of the experiment, currently one of the following:"
    echo "             MOM_solo : solo ocean model"
    echo "             MOM_SIS  : ocean-seaice model"
    echo "             CM2M     : ocean-seaice-land-atmosphere coupled climate model"
    echo "             ESM2M    : ocean-seaice-land-atmosphere coupled climate model with biogeochemistry, EarthSystemModel"
    echo "             ICCM     : ocean-seaice-land-atmosphere coupled model"
    echo 
    echo "--experiment followed by the name of the experiment of the specified type"
    echo "             To see the list of available experiments for each type use  -h --type type_name"
    if ( $type == MOM_solo ) then
    echo "             Available experiments for MOM_solo:"
    echo "             box1, box_channel1, bowl1, dome1, gyre1, iom1, mk3p51, symmetric_box1, torus1, dome_bates_blobs1"
    endif
    if ( $type == MOM_SIS ) then
    echo "             Available experiments for MOM_SIS:"
    echo "             om3_core1, om3_core3, MOM_SIS_TOPAZ, MOM_SIS_BLING, atlantic1, global_0.25_degree_NYF"
    endif
    if ( $type == CM2M ) then
    echo "             Available experiments for CM2M:"
    echo "             CM2.1p1, CM2M_coarse_BLING"
    endif
    if ( $type == ESM2M ) then
    echo "             Available experiments for ESM2M:"
    echo "             ESM2M_pi-control_C2"
    endif
    if ( $type == ICCM ) then
    echo "             Available experiments for ICCM:"
    echo "             ICCMp1"
    endif
    if ( $type == EBM ) then
    echo "             Available experiments for EBM:"
    echo "             mom4p1_ebm1"
    endif
    echo 
    echo 
    echo "--platform   followed by the platform name that has a corresponfing environ file in the ../bin dir, default is gfortran"
    echo 
    echo "--npes       followed by the number of pes to be used for this experiment"
    echo
    echo "--download_input_data  download the input data for the test case"
    echo 
    echo "Note that the executable for the run should have been built before calling this script. See MOM_compile.csh"
    echo 
    exit 1
endif
#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# Directory setting for experiment
set root          = $cwd:h          # The directory in which you checked out src
set code_dir      = $root/src       # Source code directory
set workdir       = $root/work      # Where the model is run and model output is produced
                                    # This is recommended to be a link to the $WORKDIR of the platform.
set expdir        = $workdir/$name
set inputDataDir  = $expdir/INPUT   # This is path to the directory that contains the input data for this experiment.
                                    # You should have downloaded and untared this directory from MOM4p1 FTP site.

set diagtable     = $inputDataDir/diag_table                 # path to diagnositics table
set datatable     = $inputDataDir/data_table                 # path to the data override table.
set fieldtable    = $inputDataDir/field_table                # path to the field table
set namelist      = $inputDataDir/input.nml                  # path to namelist file

set executable    = $root/exec/$platform/$type/fms_$type.x   # executable created after compilation

set archive       = $expdir                                  #Large directory to host the input and output data.
# KM.Noh 2019 
set machinefile   = /home/km109/hosts/mvapich2.hosts
#---------------------------------------------------------------------------------------


#=======================================================================================
#                   The user need not change any of the following
#=======================================================================================

if ( $debug || $valgrind ) then
    setenv DEBUG true
endif

#---------------------------------------------------------------------------------------
# Users must ensure the correct environment file exists for their platform.
source $root/bin/environs.$platform  # environment variables and loadable modules

set mppnccombine  = $root/bin/mppnccombine.$platform  # path to executable mppnccombine
set time_stamp    = $root/bin/time_stamp.csh          # path to cshell to generate the date
#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# setup directory structure
if ( ! -d $expdir )         mkdir -p $expdir
if ( ! -d $expdir/RESTART ) mkdir -p $expdir/RESTART
if ( ! -d $expdir/INPUT )   mkdir -p $expdir/INPUT

if ( ! -e $namelist ) then
    echo "ERROR: required input file does not exist $namelist."
    echo "Need to download input data? See ./MOM_run.csh -h"
    exit 1
endif
if ( ! -e $datatable ) then
    echo "ERROR: required input file does not exist $datatable."
    echo "Need to download input data? See ./MOM_run.csh -h"
    exit 1
endif
if ( ! -e $diagtable ) then
    echo "ERROR: required input file does not exist $diagtable."
    echo "Need to download input data? See ./MOM_run.csh -h"
    exit 1
endif
if ( ! -e $fieldtable ) then
    echo "ERROR: required input file does not exist $fieldtable."
    echo "Need to download input data? See ./MOM_run.csh -h"
    exit 1
endif
#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# Change to expdir
cd $expdir
@  year = $RestartYear

#---------------------------------------------------------------------------------------#
#                                        KDH-loop                                       #
#---------------------------------------------------------------------------------------#
while ( $year <= $EndYear ) 

        # KM.Noh 2019
        if ( $year == $StartYear ) then 
            cp $namelist   input.nml
            cp $datatable  data_table
            cp $diagtable  diag_table
            cp $fieldtable field_table
        else
            if ( ! -d $expdir/RESTART ) then
                echo "ERROR: required restart files do not exist."
                exit 1
            else
                \mv -f $expdir/ReSTART/* $expdir/INPUT/.
            endif
        endif

        cp $expdir/INPUT/input.nml $expdir
        cp $expdir/INPUT/*_table $expdir


#---------------------------------------------------------------------------------------
# Preprocessings
        $root/exp/preprocessing.csh
#---------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------
# for 2xCO2 - KDH-loop

        @ obsyear=$year
        @ preyear=$obsyear - 1

        echo YEAR : $year , $RestartYear , $EndYear
        echo CO2 YEAR : $year , $obsyear , $preyear

        sed -i "s/co2_dataset_entry = $preyear/co2_dataset_entry = $obsyear/g" $expdir/input.nml
#-------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# Describe specific runCommand
        set runCommand = "mpirun -machinefile $machinefile -np $npes $executable"  # KM.Noh 2019
        echo "About to run the command $runCommand"

        if ( $valgrind ) then
            set runCommand = "$mpirunCommand $npes -x LD_PRELOAD=$VALGRIND_MPI_WRAPPERS valgrind --gen-suppressions=all --suppressions=../../test/valgrind_suppressions.txt --main-stacksize=2000000000 --max-stackframe=2000000000 --error-limit=no $executable >fms.out"
        endif

        if ( $debug ) then
            set runCommand = "$mpirunCommand --debug $npes $executable >fms.out"
        endif

        echo "About to run experiment $name with model $type at `date`. The command is: $runCommand"

#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# Run the model
        $runCommand > fms.out # KM.Noh 2019

        set model_status = $status
        if ( $model_status != 0) then
            echo "ERROR: Model failed to run to completion"
            exit 1
        endif
#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# generate date for file names ---
        set begindate = `$time_stamp -bf digital`
        if ( $begindate == "" ) set begindate = tmp`date '+%j%H%M%S'`
        set enddate = `$time_stamp -ef digital`
        if ( $enddate == "" )   set enddate = tmp`date '+%j%H%M%S'`
        if ( -f time_stamp.out )  rm -f time_stamp.out
#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# combine output files
        if ( $npes > 1 ) then
            set file_previous = ""
            set multioutput = (`ls *.nc.????`)
            foreach file ( $multioutput )
                if ( $file:r != $file_previous:r ) then
                    set input_files = ( `ls $file:r.????` )
                    if ( $#input_files > 0 ) then
                        $mppnccombine -n4 -r $file:r $input_files
                        if ( $status != 0 ) then
                            echo "ERROR: in execution of mppnccombine -n4 -r on outputs"
                            echo "Command was: $mppnccombine $file:r $input_files"
                            break
                        endif
                    endif
                else
                    continue
                endif
                set file_previous = $file
            end
        endif
#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# get a tar restart file
        cd RESTART
        cp $expdir/input.nml .
        cp $expdir/*_table .
#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# combine netcdf files
        if ( $npes > 1 ) then
            # Concatenate blobs restart files. mppnccombine would not work on them.
            if ( -f ocean_blobs.res.nc.0000 ) then
                ncecat ocean_blobs.res.nc.???? ocean_blobs.res.nc
                rm ocean_blobs.res.nc.????
            endif

            # Concatenate iceberg restarts
            if ( -f icebergs.res.nc.0000 ) then
                ncrcat icebergs.res.nc.???? icebergs.res.nc
                rm icebergs.res.nc.????
            endif

            # Land restarts need to be combined with  combine-ncc
            # More simply just tar them up in this version
            set land_files = ( cana glac lake land snow soil vegn1 vegn2 )
            foreach file ( $land_files )
               set input_files = `/bin/ls ${file}.res.nc.????`
               if ( $#input_files > 0 ) then
                  tar czf ${file}.res.nc.tar $input_files
                  if ( $status != 0 ) then
                     echo "ERROR: in creating land restarts tarfile"
                     exit 1
                  endif
                  rm $input_files
               endif
            end

            set file_previous = ""
            set multires = (`ls *.nc.????`)
            foreach file ( $multires )
                if ( $file:r != $file_previous:r ) then
                    set input_files = ( `ls $file:r.????` )
                    if ( $#input_files > 0 ) then
                        $mppnccombine -n4 -r $file:r $input_files
                        if ( $status != 0 ) then
                            echo "ERROR: in execution of mppnccombine -n4 -r on restarts"
                            echo "Command was: $mppnccombine $file:r $input_files"
                        endif
                    endif
                else
                    continue
                endif
                set file_previous = $file
            end
        endif
#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
# rename ascii files with the date
        foreach out (`ls *.out`)
           mv $out ascii/$begindate.$out
        end
#---------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------
# rename nc files with the date - KDH-loop, KM.Noh 2019
        foreach ncfile (`/bin/ls *.nc`)
            mv $ncfile history/$begindate.$ncfile
        end

        unset echo
#-------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------
# move RESTART files to each year directory - KDH-loop, KM.Noh 2019
        mkdir -p $archive/BACKUP/history
        mv -f $expdir/history/* $archive/BACKUP/history
        sleep 30

        mkdir -p $archive/BACKUP/ascii
        mv -f $expdir/ascii/* $archive/BACKUP/ascii
        sleep 30

        mkdir -p $archive/BACKUP/RESTART/{$year}yr
        cp -f $expdir/RESTART/* $archive/BACKUP/RESTART/{$year}yr
        sleep 30
#-------------------------------------------------------------------------------------

        unset echo

        echo end_of_run
        echo "NOTE: Natural end-of-script for experiment $name with model $type at `date`"

end

exit 0

