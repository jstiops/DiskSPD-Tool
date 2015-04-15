<#
.SYNOPSIS
Menu driven tool for diskspd tests

.DESCRIPTION
Use diskspd with a powershell menu. Make use of predefined test patterns
		
.NOTES
Author:		Jeffrey Strik
Blog  :		Nope
Twitter:	@jefstor
Requires:	Powershell 3.0
Version   : 1.0
Tested in lab environments, Use on your own risk.
#>

#Set these vars to correct values
$TestFileSize = "10G"
$TestDuration = "60"
#output mode xml or text, -Rxml or -Rtext
$OutputMode = "-Rxml"

#================Do not edit below=================================
$PathToDiskSpd = $PSScriptRoot+"\diskspd.exe"
$TestDriveLetter = ""
$TestToPerform = ""
$OutputFileExtension = ""
$FullOutputFileName = ""
if($OutputMode -eq "-Rxml"){
    
    $OutputFileExtension = ".xml"

}else{ $OutputFileExtension = ".txt"}

Function Show-Menu {
	
	Param (
		[Parameter(Position = 0, Mandatory = $True, HelpMessage = "Enter your menu text")]
		[ValidateNotNullOrEmpty()]
		[string]$Menu,
		[Parameter(Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string]$Title = "Menu",
		[switch]$ClearScreen
	)
	
	if ($ClearScreen) { Clear-Host }
	#build the menu prompt
	$menuPrompt = $title
	#add a return
	$menuprompt += "`n"
	#add an underline
	$menuprompt += "-" * $title.Length
	$menuprompt += "`n"
	#add the menu
	$menuPrompt += $menu
	
	Read-Host -Prompt $menuprompt
}

Function MainMenu {
	$menu =@"

1: Set Driveletter - Currently set to: $TestDriveLetter

2: Choose a test command - Currently set to: $TestToPerform

3: Run Test

Q: Quit

-----

Select a task by number or Q to quit
"@
	
	Do {
		Switch (Show-Menu $menu "Diskspd tool - Main Menu" -clear) {
			"1" { SetDriveletterMenu }
			"2" { SetTestMenu }
			"3" { RunTest }
			"Q" {
				Write-output "Thanks for using this tool"
                sleep 2
				exit
			}
			Default {
				Write-Warning "Invalid Choice. Try again."
				sleep -milliseconds 750
			}
		}
	} While ($True)
}

Function SetDriveletterMenu {


	$menu+=@"

B: Back

-----

Enter a Driveletter or B to go back
"@

	Do {
		$uitkomst = Show-Menu $menu "Set drive letter" -clear 
    if ($uitkomst -eq "B" -or $uitkomst -eq "b"){
     
      MainMenu

    }else{
    
      if($uitkomst -match "[c-zC-Z]"){
        
        $TestDriveLetter = $uitkomst
        Write-Host "Drive Letter is set to $TestDriveLetter"
        sleep -Milliseconds 1
        MainMenu

      }

    }
	} While ($True)
}

Function SetTestMenu {
	$menu =@"

1: Sequential Read Test 64K

2: Sequential Write Test 64K

3: Random Read-Write 70-30 test 4K blocksize

4: Random Read-Write 70-30 test 8K blocksize

5: CommVault DDB Disk test 8 Threads and 1 Outstanding IO per thread

6: SQL Log disk test

7: SQL data disk test

8: Veeam Local Target+ with compression

9: Veeam Local Target with compression

10: Veeam LAN Target with compression

11: Veeam WAN Target with compression

12: Veeam Transform to rollbacks

13: Veeam worst case restore or Surebackup

14: Veeam best case restore or Surebackup

B: Back

-----

Select a test by number or B to go back
"@
	
	Do {
		Switch ($uitkomst=Show-Menu $menu "Select test type" -clear) {
			"1" { $TestToPerform = "TestSeqRead64K"; MainMenu }
			"2" { $TestToPerform = "TestSeqWrite64K"; MainMenu }
			"3"  { $TestToPerform = "TestRandRW70304K"; MainMenu }
			"4"  { $TestToPerform = "TestRandRW70308K"; MainMenu }
      "5" { $TestToPerform = "CommVaultDDBTest8T1o"; MainMenu}
      "6" { $TestToPerform = "SQLLogTest1T8o"; MainMenu}
      "7" { $TestToPerform = "SQLDataTest1T8o"; MainMenu}
      "8" {$TestToPerform = "VeeamLocalCompressed4M"; MainMenu}
      "9" {$TestToPerform = "VeeamLocalCompressed512K"; MainMenu}
      "10" {$TestToPerform = "VeeamLANCompressed256K"; MainMenu}
      "11" {$TestToPerform = "VeeamWANCompressed128K"; MainMenu} 
      "12" {$TestToPerform = "VeeamTransformToRollbacks"; MainMenu} 
      "13" {$TestToPerform = "VeeamWorstCaseRestore"; MainMenu}
      "14" {$TestToPerform = "VeeamBestCaseRestore"; MainMenu}
      "15" {$TestToPerform = "VeeamReverseIncremental"; MainMenu}

			"B" { MainMenu }
			Default { Write-Warning "Invalid Choice. Try again."; sleep -milliseconds 750 }
		}
	} While ($True)
}


Function RunTest {

if($TestDriveLetter -match "[c-zC-Z]" -and $TestToPerform -ne ""){

	
    clear-host
    write-host "Performing test, please wait...."
    $app = $PathToDiskSpd
    $datestamp = $(get-date -f "yyy-MM-dd HH-mm-ss")
    $FullOutputFileName = "$TestDriveLetter`:\DiskSpdTestFolder\Results $TestDriveLetter-drive $TestToPerform $datestamp$OutputFileExtension"

    #Execute the test with &
    #Supply parameters with values
    #redirect / suppress strerr to prevent diskspd from generating warnings. This prevents warnings from appearing when testing UNC paths or Drive mappings
    switch ($TestToPerform){

        "TestSeqRead64K" {

        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w0 -b64k -o8 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName 

        }
        "TestSeqWrite64K" {

        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w100 -b64k -o8 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName 

        }
        "TestRandRW70304K" {

        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w30 -b4k -r -o8 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName

        }
        "TestRandRW70308K" {

        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w30 -b8k -r -o8 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName

        }
        "CommVaultDDBTest8T1o" {

        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w50 -b4k -r -o1 -t8 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName

        }
        "SQLLogTest1T8o" {

        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w100 -b8k -o8 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName

        }
        "SQLDataTest1T8o" {

        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w30 -b8k -r -o8 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName

        }
        "VeeamLocalCompressed4M" {
        
        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w100 -b4M -o1 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName

        }
        "VeeamLocalCompressed512K" {
        
        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w100 -b512K -o1 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName

        }
        "VeeamLANCompressed256K" {
        
        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w100 -b256K -o1 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName

        }
        "VeeamWANCompressed128K" {
        
        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w100 -b128K -o1 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName

        }
        "VeeamTransformToRollbacks" {
        
        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w50 -r4K -b512K -o1 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName
        Write-Host " "
        Write-Host "Devide total MB/s by 4 to get realistic results for this test" -ForegroundColor Yellow
        
        }
        "VeeamWorstCaseRestore" {
        
        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w0 -b512K -r4K -o1 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName

        }
        "VeeamBestCaseRestore" {
        
        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w0 -b512K -o1 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName

        }
        "VeeamReverseIncremental" {
        
        (&$app -c"$TestFileSize" -d"$TestDuration" $OutputMode -w67 -b512K -r4K -o1 -t1 -h -L "$TestDriveLetter`:\DiskSpdTestFolder\testfile.dat") 2>$null | Out-File $FullOutputFileName
        Write-Host ""
        Write-Host "Devide total MB/s by 3 to get realistic results for this test" -ForegroundColor Yellow

        }

    }

    Write-host " "

    if($OutputMode -eq "-Rxml"){ ProcessResults }
    

    Write-host " "
    Write-host "End of test, check testfolder for detailed results"
    switch(read-host -Prompt "Run another test? y or n?"){
        "y" {MainMenu}
        "n" {exit}
        default {Write-Warning "Wrong entry, exiting"; Exit}
    }

    }else{

     Clear-host
     Write-host "No valid drive letter or test selection detected, returning to main menu"
     sleep -milliseconds 1000
     MainMenu

    }


}

Function ProcessResults {

$contents = [xml](Get-Content $FullOutputFileName)

# sum read and write iops and bandwith across all threads and targets
$riops = (($contents.Results.TimeSpan.Thread.Target | measure -sum -Property ReadCount).Sum) / [int]$contents.Results.Profile.Timespans.Timespan.Duration
$wiops = (($contents.Results.TimeSpan.Thread.Target | measure -sum -Property WriteCount).Sum) / [int]$contents.Results.Profile.Timespans.Timespan.Duration
$rb = [math]::round( ((($contents.Results.TimeSpan.Thread.Target | measure -sum -Property ReadBytes).Sum ) / [int]$contents.Results.Profile.Timespans.Timespan.Duration / (1024*1024) ), 2 )
$wb = [math]::round( ((($contents.Results.TimeSpan.Thread.Target | measure -sum -Property WriteBytes).Sum ) / [int]$contents.Results.Profile.Timespans.Timespan.Duration / (1024*1024) ), 2 )

#sum average latency stats
$avgLat = $contents.Results.TimeSpan.Latency.AverageTotalMilliseconds
$avgwLat = $contents.Results.TimeSpan.Latency.AverageWriteMilliseconds
$avgrLat = $contents.Results.TimeSpan.Latency.AverageReadMilliseconds

#sum CPU stats
$avgCPU = $contents.Results.TimeSpan.CpuUtilization.Average.UsagePercent


#Build return strings and joing them with a new-line delimiter
$ReturnStringIOPsAndThroughput = "IO stats: Total Read IOPs: $riops | Total Write IOPs: $wiops | Total Read Throughput (MB/s): $rb | Total Write Throughput (MB/s): $wb"
$ReturnStringLatency = "Latency stats: Total Avg Latency (ms):  $avgLat | Total Avg Write Latency(ms): $avgwLat | Total Avg Read Latency(ms): $avgrLat"
$ReturnStringCPU = "CPU stats: Total Avg CPU usage (%):  $avgCPU"
$ReturnStringIOPsAndThroughput, $ReturnStringLatency, $ReturnStringCPU -join "`n" 


}

#start the main menu display
MainMenu

