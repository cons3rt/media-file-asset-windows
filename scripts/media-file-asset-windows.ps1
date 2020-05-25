#!/usr/bin/env pwsh
<#
Use this script with no modifications to copy media files from
your asset media directory to C:\install_media.  Otherwise, update
the "installDir" variable below.
#>

$ErrorActionPreference = "Stop"
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

########################### VARIABLES ###############################

# Media file staging directory
$installDir = "C:\install_media"

# exit code
$exitCode = 0

# Configure the log file
$logTag = 'media-file-asset-windows.ps1'
$logFileTimestamp = Get-Date -f "yyyyMMdd-HHmmss"
$logFile = "C:\cons3rt-agent\log\$logTag-$logFileTimestamp.log"

######################### END VARIABLES #############################

######################## HELPER FUNCTIONS ############################

# Logging methods
function logger($level, $logstring) {
	$stamp = get-date -f "yyyyMMdd HH:mm:ss"
	"$stamp $logTag [$level]: $logstring"
}
function logErr($logstring) { logger "ERROR" $logstring }
function logWarn($logstring) { logger "WARNING" $logstring }
function logInfo($logstring) { logger "INFO" $logstring }

###################### END HELPER FUNCTIONS ##########################

######################## SCRIPT EXECUTION ############################

new-item $logfile -itemType file -force
start-transcript -append -path $logfile
logInfo "Running $LOGTAG..."

try {  
    logInfo "Starting: $LOGTAG"
	logInfo "Install Directory: $installDir"
    
	# Exit if ASSET_DIR is not set
	if ( !$env:ASSET_DIR ) {
		$errMsg="ASSET_DIR is not set."
		logErr $errMsg
        throw $errMsg
	}
	else {
	    logInfo "Found ASSET_DIR set to: $env:ASSET_DIR"
		$mediaDir="$env:ASSET_DIR\media"
		logInfo "Media directory: $mediaDir"
	}
	
    # Exit if the install media can't be found
	if ( !(test-path $mediaDir) ) {
		$errMsg="The media directory not found: $mediaDir"
		logErr $errMsg
		throw $errMsg
	}
	else {
	    logInfo "Found directory: $mediaDir"
	}
	
	# Create the install directory
	logInfo "Creating media install directory..."
	new-item $installDir -type directory -force
	
	if ($? -eq $false) {
	    $errMsg="Unable to create install directory: $installDir"
	    logErr $errMsg
        throw $errMsg
    }
    else {
        logInfo "Successfully created directory: $installDir"
    }

	# Copy the install media to the install directory
	logInfo "Copying files in $mediaDir to $installDir..."
	Copy-Item $mediaDir\* $installDir -force -recurse
	
	if ($? -eq $false) {
	    $errMsg="Unable to copy files from $mediaDir to $installDir"
	    logErr $errMsg
        throw $errMsg
    }
    else {
        logInfo "Successfully copied files from $mediaDir to $installDir"
    }
	
	# Clean up
	logInfo "Deleting the directory..."
	remove-item $mediaDir -recurse -force
	
	if ($? -eq $false) {
	    $warnMsg="Unable to delete directory: $mediaDir, files may exist twice on this system"
	    logWarn $warnMsg
    }
    else {
        logInfo "Successfully deleted directory: $mediaDir"
    }
}
catch {
    logErr "Caught exception after $($stopwatch.Elapsed): $_"
    $exitCode = 1
    $kill = (gwmi win32_process -Filter processid=$pid).parentprocessid
    if ( (Get-Process -Id $kill).ProcessName -eq "cmd" ) {
        logErr "Exiting using taskkill..."
        Stop-Transcript
        TASKKILL /PID $kill /T /F
    }
}
finally {
    logInfo "$LOGTAG complete in $($stopwatch.Elapsed)"
}

###################### END SCRIPT EXECUTION ##########################

logInfo "Exiting with code: $exitCode"
stop-transcript
get-content -Path $logfile
exit $exitCode
