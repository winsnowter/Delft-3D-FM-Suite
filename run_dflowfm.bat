@ echo off
title run_dflowfm_parallel_20cores

    rem This script runs Delft3D-FM in parallel mode with 20 cores on Windows
    rem
    rem When using intelMPI for the first time on a machine:
    rem Execute "hydra_service.exe -install" as administrator:
    rem     "Windows Start button" -> type "cmd", right-click "Command Prompt", "Run as Administrator"
    rem     In this command box:
    rem         cd "C:\Program Files\Deltares\Delft3D FM Suite 2025.01 HMWQ\plugins\DeltaShell.Dimr\kernels\x64\share\bin"
    rem         hydra_service.exe -install
    rem         mpiexec.exe -register -username <user> -password <password> -noprompt

setlocal enabledelayedexpansion

set workdir=%CD%
echo Working directory: %workdir%

    rem Set the Delft3D installation path
set D3D_HOME=C:\Program Files\Deltares\Delft3D FM Suite 2025.01 HMWQ\plugins\DeltaShell.Dimr\kernels\x64

    rem Change to dflowfm directory where the model files are located
cd /d "%workdir%\dflowfm"
echo Model directory: %CD%

    rem Step 1: Partition the model into 20 domains
echo.
echo ============================================
echo Step 1: Partitioning model into 20 domains
echo ============================================
call "%D3D_HOME%\bin\run_dflowfm.bat" "--partition:ndomains=20:icgsolver=6" HK-DFM11.mdu

    rem Step 2: Run DIMR in parallel with 20 processes
echo.
echo ============================================
echo Step 2: Running DIMR with 20 MPI processes
echo ============================================
call "%D3D_HOME%\bin\run_dimr_parallel.bat" 20 dimr.xml

    rem Step 3: Merge output files
echo.
echo ============================================
echo Step 3: Merging output map files
echo ============================================
cd DFM_OUTPUT_HK-DFM11
dir /b *0*_map.nc > merge_filelist.txt
call "%D3D_HOME%\dflowfm\scripts\run_dfmoutput.bat" mapmerge --force --listfile "merge_filelist.txt"

    rem Return to original directory
cd /d "%workdir%"

echo.
echo ============================================
echo Completed!
echo ============================================

    rem To prevent the DOS box from disappearing immediately
pause
