# -----------------------------------------------------------------------------
# Compare-GPO.ps1
# ed wilson, msft, 7/13/2010
#
# HSG-07-15-2010
# -----------------------------------------------------------------------------
#requires -version 2.0
Param(
  [string]$domain ="col-0310000z01.local",
  [string]$server = "serveur01.col-0310000z01.local",
  [string]$gponame = "Materiel - Last,Materiel - v1",
  [string]$folder = "c:\mnt",
  [switch]$user,
  [switch]$computer
 )

Function Get-MyModule
{
 Param([string]$name)
 if(-not(Get-Module -name $name))
   {
    if(Get-Module -ListAvailable |
        Where-Object { $_.name -eq $name })
       {
        Import-Module -Name $name
        $true
       } #end if module available then import
    else { $false } #module not available
    } # end if not module
  else { $true } #module already loaded
} #end function get-MyModule

Function Get-GPOAsXML
{
 Param(
  [string[]]$gponame,
  [string]$domain,
  [string]$server,
  [string]$folder
 )
  $gpoReports = $null
  ForEach($gpo in $gpoName)
   {
     $path = Join-Path -Path $folder -ChildPath "$gpo.xml"
     (Get-GPO -Name $gpo -Domain $domain -Server $server).`
      GenerateReportToFile("xml",$path)
     [array]$gpoReports + $path
   }
   Return $gpoReports
} #end get-gpoasxml

Function Compare-XMLGPO
{
 Param([string[]]$gpoReports, $user, $computer)
    [xml]$xml1 = Get-Content -Path $gpoReports[0]
    [xml]$xml2 = Get-Content -Path $gpoReports[1]
    $regpolicyComputerNodes1 = $xml1.gpo.Computer.extensiondata.extension.ChildNodes |
      Select-Object name, state

    $regpolicyComputerNodes2 = $xml2.gpo.Computer.extensiondata.extension.ChildNodes |
      Select-Object name, state

    $regpolicyUserNodes1 = $xml1.gpo.User.extensiondata.extension.ChildNodes |
      Select-Object name, state
    $regpolicyUserNodes2 = $xml2.gpo.User.extensiondata.extension.ChildNodes |
      Select-Object name, state
    if($computer)
      {
       Try {
       "Comparing Computer GPO's $($gpoReports[0]) to $($gpoReports[1])`r`n"
         Compare-Object -ReferenceObject $regpolicyComputerNodes1 `
          -DifferenceObject $regpolicyComputerNodes2 -IncludeEqual `
          -property name}
        Catch [system.exception]
         {
          if($regPolicyComputerNodes1)
            {
             "Computer GPO $($gpoReports[0]) settings `r`f"
             $regPolicyComputerNodes1
            }
            else { "Computer GPO $($gpoReports[0]) not set" }
          if($regPolicyComputerNodes2)
            {
             "Computer GPO $($gpoReports[1]) settings `r`f"
             $regPolicyComputerNodes2
            }
          else { "Computer GPO $($gpoReports[1]) not set"}
         } #end catch
      } #end if computer
    if($user)
      {
       Try {
       "Comparing User GPO's $($gpoReports[0]) to $($gpoReports[1])`r`n"
       Compare-Object -ReferenceObject $regpolicyUserNodes1 `
        -DifferenceObject $regpolicyUserNodes2  -SyncWindow 5 -IncludeEqual `
        -property name}
       Catch [system.exception]
       {
        if($regPolicyUserNodes1)
            {
             "User GPO $($gpoReports[0]) settings `r`f"
             $regPolicyUserNodes1
            }
            else { "User GPO $($gpoReports[0]) not set" }
          if($regPolicyUserNodes2)
            {
             "User GPO $($gpoReports[1]) settings `r`f"
             $regPolicyUserNodes2
            }
          else { "User GPO $($gpoReports[1]) not set"}
         }
       } #end catch
} #end function compare-XMLGPO

# *** Entry Point to Script ***

if(-not ($user -or $computer))
 { "Please specify either -computer or -user when running script" ; exit}
If(-not (Get-MyModule -name "GroupPolicy")) { exit }

$gpoReports = Get-GpoAsXML -gponame $gponame.split(",") -server $server -domain $domain -folder $folder

Compare-XMLGPO -gpoReports $gpoReports -user $user -computer $computer