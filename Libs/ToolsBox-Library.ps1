<#
.SYNOPSIS
ToolsBox-Library.ps1

.DESCRIPTION
Fouilli de fonctions.

.AUTEUR
Emmanuel Fournier
mailto:emmanuel.fournier@econocom.com

.PREREQUIS
PowerShell Version 2

.NOTES

Suivi de version:
V1.00, 21/09/2019 - Version initiale
#>



#requires -version 2



# --------------------------------------------------------------------------------------------
# Fonctions
# --------------------------------------------------------------------------------------------

# Affiche et enregistre dans le journal les messages de traitement, d'erreurs.
# En cas d'appel avec un code d'erreur, défini la variable $AAMExitCode et
# termine l'éxécution avec le code d'erreur en sortie.
#
# @param string $Message Le message
# @param string $Level Le niveau du message : 'INFO' (défaut), 'WARNING', 'ERROR' ou 'LOG'.
# Si Warning ou Error, le message est affiché en mode warning, si Info, le message est
# affiché en mode normal, si Log le message n'est pas affiché mais seulement enregistré dans le log.
# @param int $ExitCode Le code d'erreur
function Audit ( [string] $Message, [string] $Level = "INFO", [int] $ExitCode = 0 ) {
	$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
	$InFileLvl = $Level
	if($Level -eq "LOG" -or $Level -eq "HOST"){
		$InFileLvl = "INFO"
	}
	$Line = "$Stamp`:$InFileLvl`:$Message"
	if((Isset -var "LogFile")){
		Add-Content $LogFile -Value $Line
	}
	switch($Level){
		"WARNING"{
			Write-Host -ForegroundColor Yellow -Object $Message
		}
		"ERROR"{
			Write-Host -ForegroundColor Red -Object $Message
			if($ExitCode -gt 0){
				Write-Host -ForegroundColor White -Object "..."
				$key = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
				Write-Host ""
			}
		}
		"LOG"{}
		"HOST"{
			Write-Host $Message
		}
		default{
			Write-Output $Message
		}
	}
	if($ExitCode -gt 0){
		Set-Variable -Name 'AAMExitCode' -Value $ExitCode -Scope 1
		exit $ExitCode
	}
}

# Test si un object possède une propriété ou non
#
# @param object $objet L'objet à tester
# @param string $property Le nom de la propriété à vérifier
# @return boolean Retourne $True si l'objet possède la propriété, $False autrement.
#
function Check-ObjectProperty($objet,[string]$property){
    $t = $objet.GetType().Name
    if($t -eq "Hashtable"){
        return $objet.ContainsKey($property)
    }else{
	    $members = $objet | Get-Member
        if ($members -ne $null -and $members.count -gt 0){
            foreach($member in $members){
                if(($member.MemberType -eq "NoteProperty") -and ($member.Name -eq $property)){
                    return $true
                }
            }
            return $false
        }else{
            return $false;
        }
    }
}



# Mini Tests

# isset
#
# @param string $var La variable à tester
# @return boolean Retourne $True si la variable est définie, $False autrement.
function Isset ([string]$var) {
	return [bool](Get-Variable -Name $var -ErrorAction SilentlyContinue)
}

# Test si une string est vide ou non ( == null ou == "" ou == "            " )
#
# @param string $var La variable à tester
# @return boolean Retourne $True si la variable est vide, $False autrement.
function Empty ([string]$var) {
	return [string]::IsNullOrWhiteSpace($var)
}

# Teste si une commande PowerShell est définie dans l'environnement actuel
#
# @param string $cmdname La commande à vérifier
# @return boolean Retourne $True si la commande est définie, $False autrement.
function Check-Command([string]$cmdname){
	return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Teste si un alias PowerShell est défini dans l'environnement actuel
#
# @param string $alias L'alias à vérifier
# @return boolean Retourne $True si l'alias est défini, $False autrement.
function Check-Alias([string]$alias){
	return [bool](Get-Alias -Name $alias -ErrorAction SilentlyContinue)
}

# Teste si un utilisateur est défini dans l'annuaire
#
# @param string $identity Le nom de compte de l'utilisater à vérifier
# @return boolean Retourne $True si l'utilisateur existe déjà, $False autrement.
function Check-ADUser([string]$identity){
	try{
		return [bool](Get-ADUser -Identity "$identity" -ErrorAction SilentlyContinue)
	}catch{
		return $False
	}
}

# Teste si un groupe existe ou pas
#
# @param string $nom Nom du groupe
# @return boolean Retourne $True si le groupe existe, $False autrement.
function Check-ADGroup([string]$nom){
	try{
		return [bool](Get-ADGroup "$nom" -ErrorAction SilentlyContinue)
	}catch{
		return $False
	}
}

# Teste si un utilisateur est dans un groupe ou pas
#
# @param string $user L'utilisateur
# @param string $group Le groupe
# @return boolean Retourne $True si l'utilisateur est dans le groupe, $False autrement.
function Check-ADUserInGroup([string]$user,[string]$group){
	If(Check-ADUser -Identity $user){
		If((Get-ADUser $user -Properties memberof -ErrorAction SilentlyContinue).memberof -like "CN=$group*") {
			return $True
		}Else{
	        return $False
		}
	}else{
		return $False
	}
}


# Retourne un lot de caractères de façon aléatoire
#
# @param int $length Longueur du jeu retourné
# @param string $characters Lot de caractères dans lequel choisir les caractères retournés de façon aléatoire
# @return string Retourne le jeu de caractères
function Get-RandomCharacters([int]$length,[string]$characters) {
	$random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
	$private:ofs=""
	return [String]$characters[$random]
}

# Mélange les caractères donnés
#
# @param string $inputString Jeu de caractères à mélanger.
# @return string Retourne les caractères mélangés.
function Scramble-String([string]$inputString){
	$characterArray = $inputString.ToCharArray()
	$scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length
	$outputString = -join $scrambledStringArray
	return $outputString
}

# Construit un mot de passe fort
#
# @param int $length Longueur du mot de passe
# @return string Retourne le mot de passe
function Build-StrongPassword([int]$length=12){
	if($length -lt 4){
		$length = 4
	}
	$n = [Math]::Floor($length/4)
	$r = $length%4
	$password = Get-RandomCharacters -length $($n+$r) -characters 'abcdefghiklmnoprstuvwxyz'
	$password += Get-RandomCharacters -length $n -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
	$password += Get-RandomCharacters -length $n -characters '1234567890'
	$password += Get-RandomCharacters -length $n -characters '!§$%&()=?}][{@#*+'
	$password = Scramble-String $password
	return $password
}

# Echo env
function WOEnv(){
    Write-Output ""
    Audit "Host : $env:COMPUTERNAME"
    $PSVer = $PSVersionTable.PSVersion.ToString()
    Audit "OS : $env:OS - PS : $PSVer"
    Audit "PS RunUser : $env:USERDOMAIN\$env:USERNAME"
    Write-Output ""
}




<#
.SYNOPSIS
Peuple un tableau d'options avec les valeurs par défaut
si le tableau ne définit pas les options par défaut.
jQuery.Extend();

.PARAMETER $Options
Le tableau des options.
.PARAMETER $Defauts
Le tableau des valeurs par défaut.

.OUTPUTS
Retourne le tableau d'options modifié ou pas.

.NOTES
Ces tableaux sont des tableaux associatifs (hashtable)
#>
function Extend{
	param(
		[Parameter(Position=0,Mandatory=$false)]
		[hashtable]
		$Options,
		[Parameter(Position=1,Mandatory=$true)]
		[hashtable]
		$Defauts
	)
	if($Options -eq $null){
		return $Defauts
	}
	$_Copy = $Defauts.Clone()
	return __Extend__ -Options $Options -Defauts $Defauts -_Copy $_Copy -ErrorAction SilentlyContinue
}
function __Extend__{
	param(
		[Parameter(Position=0,Mandatory=$false)]
		[hashtable]
		$Options,
		[Parameter(Position=1,Mandatory=$true)]
		[hashtable]
		$Defauts,
		[Parameter(Position=2,Mandatory=$true)]
		[hashtable]
		$_Copy
	)
	foreach($k in $Defauts.Keys){
		if($Options.$k){
			$_Copy.$k = $Options.$k
		}else{
			if($Defauts.$k.GetType().name -eq "Hashtable" -and $Options.$k){
				$_Copy.$k = __Extend__ -Options $Options.$k -Defauts $Defauts.$k -_Copy $_Copy.$k
			}else{
				if($Options.$k){
					$_Copy.$k = $Options.$k
				}
			}
		}
	}
	return $_Copy
}



function renderMDHashTable{
	param([Parameter(Position=0,Mandatory=$false)][hashtable]$a,[Parameter(Position=1,Mandatory=$false)][int]$i=1)
	if($i -eq 1){
		Write-Host "@{"
	}
	foreach($k in $a.Keys){
		if($a.$k.GetType().name -eq "Hashtable"){
			Write-Host "$('   '*$i)$k = @{"
			$j = $i + 1
			renderMDHashTable $a.$k $j
			Write-Host "$('   '*$i)}"
		}else{
			Write-Host "$('   '*$i)$k = $($a[$k])"
		}
	}
	if($i -eq 1){
		Write-Host "}"
	}
}


if(!(Check-Alias fsl)){
	function Format-SortedList {
		param (
	        [Parameter(ValueFromPipeline = $true)]
	        [Object]$x
	    )
		$x | fl -property ($x| gm | sort name).name
	}
	New-Alias -Name fsl -Value Format-SortedList
}



# Add icon extractor from

if (-not ([System.Management.Automation.PSTypeName]'System.IconExtractor').Type){
	$code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

namespace System{
	public class IconExtractor{
		public static Icon Extract(string file, int number, bool largeIcon){
			IntPtr large;
			IntPtr small;
			ExtractIconEx(file, number, out large, out small, 1);
			try{
				return Icon.FromHandle(largeIcon ? large : small);
			}catch{
				return null;
			}
		}
		[DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
		private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);
	}
}
"@
	Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing
}



# Add function to set window foreground

Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class ISwf {
     [DllImport("user32.dll")]
     [return: MarshalAs(UnmanagedType.Bool)]
     public static extern bool SetForegroundWindow(IntPtr hWnd);
  }
"@



# --------------------------------------------------------------------------------------------
# Chargement de l'environnement
# --------------------------------------------------------------------------------------------

# Pour la création du compte utilisateur dans Active Directory
Import-Module ActiveDirectory


# Long domain
$DomaineDNS = (Get-WmiObject Win32_ComputerSystem).Domain
# Short domain
$Domaine = ([regex]::match($DomaineDNS,'([^.]+)').Groups[1].Value).ToUpper()
# Hostname without domain
$Hostname = $env:COMPUTERNAME
# IP Addresses of current computer, could be multiples addresses !
$IPsServer = (Get-WMIObject -class "Win32_NetworkAdapterConfiguration" -computername $Hostname -ErrorAction SilentlyContinue | Where{$_.IpEnabled -Match "True"}).IPAddress
# IP address of current computer read from DNS (principal address)
$IPserver = (Resolve-DnsName -Name ($Hostname + "." + $DomaineDNS) -DnsOnly).IPAddress
