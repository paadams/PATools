$PAErrorLogPreference = 'C:\temp\pa-errors.log'

function Get-PASystemInfo {
    <#
.SYNOPSIS
Retrieves key system version and model information
from or a list of computers.
.DESCRIPTION
Get-SystemInfo uses Windows Management Instrumentation
(WMI) to retrieve information from one or more computers.
Specify computers by name or by IP address.
.PARAMETER ComputerName
One or more computer names or IP addresses.
.PARAMETER LogErrors
Specify this switch to create a text log file of computers
that could not be queried.
.PARAMETER ErrorLog
When used with -LogErrors, specifies the file path and name
to which failed computer names will be written. Defaults to
C:\temp\Get-SystemInfo_ErrorLog.txt.
.EXAMPLE
 Get-Content names.txt | Get-SystemInfo
.EXAMPLE
 Get-SystemInfo -ComputerName SERVER1,SERVER2
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,
                    ValueFromPipeline=$true,
                    HelpMessage="Computer name or IP address")]
        [Alias('hostname')]
        [string[]]$ComputerName,

        [string]$ErrorLog = $PAErrorLogPreference,

        [switch]$LogErrors
    )
    BEGIN {
        Write-verbose "Error log will be $ErrorLog"
    }
    PROCESS {
        Write-Verbose "Beginning PROCESS block"
        foreach ($computer in $ComputerName){
            Write-Verbose "Querying $computer"
            Try {
                $everything_ok = $true
                $os = Get-WmiObject -class Win32_OperatingSystem -ComputerName $computer -ErrorAction Stop
            } Catch {
                $everything_ok = $false
                Write-Warning "$computer failed. $_.Exception.Message"
                if ($LogErrors){
                    $computer | Out-File $ErrorLog -Append
                    Write-Warning "Logged to $ErrorLog"
                }
            }
            if($everything_ok){
            $os = Get-WmiObject -class Win32_OperatingSystem -ComputerName $computer
            $comp = Get-WmiObject -class Win32_ComputerSystem -ComputerName $computer
            $bios = Get-WmiObject -class Win32_BIOS -ComputerName $computer
        
            $props = @{'ComputerName' = $computer;
                        'OSVersion' = $os.version;
                        'SPVersion' = $os.servicepackmajorversion;
                        'BIOSSerial' = $bios.serialnumber;
                        'Manufacturer' = $comp.Manufacturer;
                        'Model' = $comp.Model;
                        'LastBootTime' = $os.ConvertToDateTime($os.LastBootUpTime)}
            Write-Verbose "WMI queries complete"  
            $obj = New-Object -TypeName PSObject -Property $props
            $obj.PSObject.TypeNames.Insert(0,'PA.SystemInfo')
            Write-Output $obj         
            }
        }
    }
    END {}

} # Get-SystemInfo function

Export-ModuleMember -Variable PAErrorLogPreference
Export-ModuleMember -Function Get-PASystemInfo