<#
.SYNOPSIS
Traitement automatisé des GPOs CD31

.DESCRIPTION
Accompagné des fichiers de schéma et des stratégies de groupe
de référence, ce script met-à-jour le schéma, sauvegarde les
stratégies du collège et les remplace par les stratégies de référence.
Il patche aussi les valeurs propres au collège. Enfin, il permet
de faire des stratégies du collège, une fois modifiées, les stratégies
de référence, permettant ainsi de les restaurer rapidement. Si des
modifications sont effectuées dans l'établissement, elles peuvent
être sauvegardées et/ou devenir les stratégies de référence en utilisant
le paramètre MakeCurrentAsRef. Ces étapes sont, dans l'ordre indiqué
ci-dessus, toutes exécutées. Avec les paramètres, chacune
d'elles peut être désactivée. Pour plus d'informations, exécuter :
Get-Help Restore-GPO.ps1 -full

Le dossier 'Backup' contient les sauvegardes horodatées, le dossier
'Referentiel' contient les stratégies de référence. Le dossier 'PolicyDefinitions'
contient les modèles de stratégies (schéma).

.PARAMETER DomainEtab
Le domaine du collège (COL-RNE0X).
.PARAMETER URLEtab
L'adresse du site web CD31 du collège.
.PARAMETER IPProxy
L'adresse IPv4 du Proxy Web EOLE.

.PARAMETER BackupOnlyUser
Switch pour ne sauvegarder que les stratégies utilisateur.
Inactif si DisableBackupCurrentGPO est utilisé.
.PARAMETER BackupOnlyMachine
Switch pour ne sauvegarder que les stratégies machine.
Inactif si DisableBackupCurrentGPO est utilisé.

.PARAMETER DisableDeploySchema
Switch pour désactiver le traitement de la mise-à-jour du schéma.
.PARAMETER DisableBackupCurrentGPO
Switch pour désactiver la sauvegarde des stratégies du site.
.PARAMETER DisableRestoreRefGPO
Switch pour désactiver la restauration des stratégies de référence.
.PARAMETER DisablePatchValues
Switch pour désactiver le questionnaire et la modification des valeurs.
.PARAMETER DisableMakeCurrentAsRef
Switch pour désactiver le traitement en fin de sequence
qui propose le remplacement du référentiel par les stratégies
courantes.

.PARAMETER MakeCurrentAsRef
Switch qui désactive tout les autres traitements et fait des stragégies
courantes le nouveau référentiel. Equivalent à utiliser tous les paramètres
de d"sactivation sauf DisableMakeCurrentAsRef.


.NOTES

Version :
V1.00, 06/02/2020 - Version initiale
Emmanuel Fournier
mailto:emmanuel.fournier@econocom.com

Paramètres :
Les paramètres communs ne sont pas pris en charge par ce script.

TODO :
- Patcher "Default Domain Controllers Policy" pour interdire l'ouverture d'unse session locale
pour Adminsta; G_Modele; G_Profs; G_Eleves; G_Pad.
- Ajouter la configuration des scripts de démarrage, arrêt machine
et ouverture et fermeture de session utilisateur.

.INPUTS
Aucun. Ce script ne gère aucun objet reçus en entrée.

.OUTPUTS
Aucun. Ce script ne génère aucun objet en sortie.
#>


#requires -version 2


# --------------------------------------------------------------------------------------------
# Init
# --------------------------------------------------------------------------------------------

[CmdletBinding()]
param(
    [Parameter(Position=0,Mandatory=$False)] [string]$DomainEtab,
    [Parameter(Position=1,Mandatory=$False)] [string]$URLEtab,
    [Parameter(Position=2,Mandatory=$False)] [string]$IPProxy,
    [Parameter(Position=3,Mandatory=$False)] [switch]$BackupOnlyUser,
    [Parameter(Position=4,Mandatory=$False)] [switch]$BackupOnlyMachine,
    [Parameter(Position=5,Mandatory=$False)] [switch]$DisableDeploySchema,
    [Parameter(Position=6,Mandatory=$False)] [switch]$DisableBackupCurrentGPO,
    [Parameter(Position=7,Mandatory=$False)] [switch]$DisableRestoreRefGPO,
    [Parameter(Position=8,Mandatory=$False)] [switch]$DisablePatchValues,
	[Parameter(Position=9,Mandatory=$False)] [switch]$DisableMakeCurrentAsRef,
    [Parameter(Position=10,Mandatory=$False)] [switch]$MakeCurrentAsRef
)

# Environnement
$rootPath = (Split-Path $script:MyInvocation.MyCommand.Path)+"\"
# col-RNE0X.local
$DomaineDNS = (Get-WmiObject Win32_ComputerSystem).Domain
# col-RNE0X
$Domaine = [regex]::match($DomaineDNS,'([^.]+)').Groups[1].Value


# --------------------------------------------------------------------------------------------
# Paramètres systèmes
# --------------------------------------------------------------------------------------------

# Pour forcer l'activation ou désactivation des sous-traitements
$ForceDisableDeploySchema = $False
$ForceDisableBackupCurrentGPO = $False
$ForceDisableRestoreRefGPO = $False
$ForceDisablePatchValues = $False
$ForceDisableMakeCurrentAsRef = $False


# --------------------------------------------------------------------------------------------
# Traitement
# --------------------------------------------------------------------------------------------

# Affichage intro
Clear-Host
Write-Host "`r`nTraitement des GPOs`r`n"
Write-Host "------------------------------------------------------------------------`r`n"

Write-Host "Host : $env:COMPUTERNAME"
$PSVer = $PSVersionTable.PSVersion.ToString()
Write-Host "OS : $env:OS - PS : $PSVer"
Write-Host "PS RunUser : $env:USERDOMAIN\$env:USERNAME"
Write-Host ""


# Au final, est-ce qu'on effectue les traitements
$DoDeploySchema = $ForceDisableDeploySchema -eq $False -and $DisableDeploySchema -eq $False -and $MakeCurrentAsRef -eq $False
$DoBackupCurrentGPO = $ForceDisableBackupCurrentGPO -eq $False -and $DisableBackupCurrentGPO -eq $False -and $MakeCurrentAsRef -eq $False
$DoRestoreRefGPO = $ForceDisableRestoreRefGPO -eq $False -and $DisableRestoreRefGPO -eq $False -and $MakeCurrentAsRef -eq $False
$DoPatchValues = $ForceDisablePatchValues -eq $False -and $DisablePatchValues -eq $False -and $MakeCurrentAsRef -eq $False
$DoMakeCurrentAsRef = $ForceDisableMakeCurrentAsRef -eq $False -and $DisableMakeCurrentAsRef -eq $False
# Aucun traitement actif : fin du script !
if ( $DoDeploySchema -eq $False -and $DoBackupCurrentGPO -eq $False -and $DoRestoreRefGPO -eq $False -and $DoPatchValues -eq $False -and $DoMakeCurrentAsRef -eq $False ) {
	Write-Host "Aucun traitement n'est activé ... !?`r`n"
	Exit
}


# Déploiement du schéma
if ( $DoDeploySchema ) {
	Write-Host ">> Déploiement du schéma ..."

	# Si le répertoire PolicyDefinitions n'existe pas, on le créé :
	If ( ( Test-Path "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\PolicyDefinitions\" ) -ne $true ) {
		Write-Host "  - Création des répertoires ..."
	    $tmp = New-Item -path "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\PolicyDefinitions" -ItemType directory
	    $tmp = New-Item -path "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\PolicyDefinitions\fr-FR\" -ItemType directory
	}
	# Mise en place des modèles de stratégies :
	If ( ( Test-Path "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\PolicyDefinitions\" ) -eq $true ) {
		Write-Host "  - Mise en place des modèles de stratégies ..."
		Copy-Item "$rootPath\PolicyDefinitions" -Destination "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\" -Recurse -force
	}
}


# Sauvegarde des GPO
if ( $DoBackupCurrentGPO ) {
	Write-Host ">> Sauvegarde des stragégies en service ..."
	$TimeStamp = ( Get-Date -format "yyyyMMddHHmmss" )
	$BackupPath = $rootPath + "\Backups\GpoBackups_" + $Domaine + "_" + $TimeStamp

	if ( $BackupOnlyMachine -eq $False -or $BackupOnlyUser -eq $True ) {
		Write-Host "  - Création du répertoire pour la sauvegarde utilisateur ..."
		$tmp = New-Item -ItemType directory -path "$BackupPath\Utilisateurs" -force
		Write-Host "  - Sauvegarde des stratégies utilisateurs ..."
		$tmp = Backup-Gpo -Name "Utilisateurs" -Path "$BackupPath\Utilisateurs" -Comment ("Sauvegarde GPO Utilisateur " + $Domaine + " " + $TimeStamp)
	}
	if ( $BackupOnlyUser -eq $False -or $BackupOnlyMachine -eq $True ) {
		Write-Host "  - Création du répertoire pour la sauvegarde ordinateur ..."
		$tmp = New-Item -ItemType directory -path "$BackupPath\Matériel" -force
		Write-Host "  - Sauvegarde des stratégies ordinateurs ..."
		$tmp = Backup-Gpo -Name "Matériel" -Path "$BackupPath\Matériel" -Comment ("Sauvegarde GPO Matériel " + $Domaine + " " + $TimeStamp)
	}
}


# Importation des nouveaux paramètres dans les GPO (les anciens contenus seront écrasés !)
if ( $DoRestoreRefGPO ) {
	Write-Host ">> Activation des stratégies de référence ..."
	Write-Host "  - Importation des stratégies utilisateurs ..."
	$tmp = Import-Gpo -BackupGpoName "Utilisateurs" -TargetName "Utilisateurs" -path "$rootPath\Referentiel\Utilisateurs" -CreateIfNeeded
	Write-Host "  - Importation des stratégies ordinateurs ..."
	$tmp = Import-Gpo -BackupGpoName "Matériel" -TargetName "Matériel" -path "$rootPath\Referentiel\Matériel" -CreateIfNeeded
}


# Adaptation des valeurs
if ( $DoPatchValues ) {
	Write-Host ">> Personnalisation des valeurs du site ..."

	while ( $DomainEtab -cnotmatch "^COL-\d{7}[A-Z]\d{2}$" ) {
		$DomainEtab = Read-Host -Prompt "  - Quelle est le domaine (AD sans .local) de l'établissement (ex : COL-0311850T01) "
	}
	while ( $URLEtab -notmatch "^http[s]?://" ) {
		$URLEtab = Read-Host -Prompt "  - Quelle est l'adresse du site de l'établissement (ex : https:// ...) "
	}
	while ( $IPProxy -notmatch "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$" ) {
		$IPProxy = Read-Host -Prompt "  - Quelle est l'adresse IPv4 du Proxy Web EOLE (ex : 10.255.23.156) "
	}

	# Extraction du RNE depuis le domaine
	$tmp = $DomainEtab -cmatch "^COL-(\d{7}[A-Z])\d{2}$"
	$RNEEtab = $Matches.1
	Write-Host "  - RNE de l'établissement : $RNEEtab"

	# Avec le RNE, ping sur RNE.index-education.net pour récupération de l'@IP Pronote
	if ( Test-Connection -ComputerName $RNEEtab".index-education.net" -Count 1 -Quiet ) {
		$IPPronote = (Test-Connection -ComputerName $RNEEtab".index-education.net" -Count 1).IPV4Address.ToString()
		Write-Host "  - Adresse IP Pronote : $IPPronote"
	}else{
		Write-Host "  - Aucune adresse IP Pronote relevée pour le nom $RNEEtab.index-education.net !"
		$IPPronote = ""
		while ( $IPPronote -notmatch "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$" ) {
			$IPPronote = Read-Host -Prompt "  - Quelle est l'adresse IPv4 Pronote (ex : 46.33.154.23) "
		}
	}

	# Construction adresse IP Serveur01 depuis l'adresse du proxy
	$octs = $IPProxy -split "\."
	$prefixIP = $octs[0] + "." + $octs[1] + "." + $octs[2] + "."
	$IPRouteur = $prefixIP + ([int]$octs[3] + 2)
	Write-Host "  - Adresse IP PFS : $IPRouteur"
	$IPServeur01 = $prefixIP + ([int]$octs[3] + 1)
	Write-Host "  - Adresse IP Serveur01 : $IPServeur01"

	# Patch du registre pour adapter les valeurs
	#
	# -Type =
	#  Unknown
	#  String
	#  ExpandString
	#  Binary
	#  DWord
	#  MultiString
	#  QWord
	#

	# >>> Machine <<<
	Write-Host ">> Sauvegarde des valeurs du site dans les stratégies de groupe du système ..."
	Write-Host "  - Matériel"
	Write-Host "    - Stratégies"

	# - Magret, Serveur3
	Write-Host "      - Modèles > Magret > 7. Application MAGRET > 7.1 Paramètres du serveur MAGRET"
	Write-Host "         @ IP du serveur MAGRET : $IPServeur01"
	$tmp = Set-GPRegistryValue -Name "Matériel" -key "HKLM\Software\Magret" -ValueName "IPServeurMagret" -Type String -value $IPServeur01
	Write-Host "         @ Nom du domaine MAGRET : $DomainEtab"
	$tmp = Set-GPRegistryValue -Name "Matériel" -key "HKLM\Software\Magret" -ValueName "DomaineMagret" -Type String -value $DomainEtab
	Write-Host "         @ Nom du serveur MAGRET : \\SERVEUR01"
	$tmp = Set-GPRegistryValue -Name "Matériel" -key "HKLM\Software\Magret" -ValueName "ServeurMagret" -Type String -value "\\SERVEUR01"
	# - Magret, Proxy
	Write-Host "      - Modèles > Magret > 4. Réseau et Accès distant"
	Write-Host ("         @ Serveur proxy pour les applications Window 8.1 et 10 : " + $IPProxy + ":3128")
	$tmp = Set-GPRegistryValue -Name "Matériel" -key "HKLM\Software\Policies\Microsoft\Windows\NetworkIsolation" -ValueName "DomainProxies" -Type String -value ($IPProxy + ":3128")



	# >>> Utilisateurs <<<
	Write-Host "  - Utilisateurs"
	Write-Host "    - Stratégies"

	# - Composants Windows, Edge
	Write-Host "      - Modèles > Composants Windows > Microsoft Edge"
	Write-Host "         @ Page d'accueil du collège : $URLEtab"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Microsoft\MicrosoftEdge\Internet Settings" -ValueName "ProvisionedHomePages" -Type String -value "<$URLEtab>"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Microsoft\MicrosoftEdge\Internet Settings" -ValueName "ConfigureHomeButton" -Type DWord -value 2
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Microsoft\MicrosoftEdge\Internet Settings" -ValueName "HomeButtonURL" -Type String -value "$URLEtab"

	# - Magret, Internet Explorer
	Write-Host "      - Modèles > Magret > 8. Composants Windows > 8.10 Internet Explorer"
	Write-Host "         @ Activation du proxy : activée"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName "ProxyEnable" -Type DWord -value 1
	Write-Host ("         @ Adresse IP:Port du proxy : " + $IPProxy + ":3128")
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName "ProxyServer" -Type String -value ($IPProxy + ":3128")
	Write-Host "         @ Exception du proxy : 10.*;<local>;$IPPronote"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName "ProxyOverride" -Type String -value "10.*;<local>;$IPPronote"
	Write-Host "         @ Page d'accueil du collège : $URLEtab"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Microsoft\Internet Explorer\Main" -ValueName "Start Page" -Type String -value $URLEtab

	# - Composants Windows, Internet Explorer
	Write-Host "      - Modèles > Composants Windows > Internet Explorer"
	Write-Host "         @ Désactiver la modification de la page d'accueil : activée"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Microsoft\Internet Explorer\Main" -ValueName "Start Page" -Type String -value $URLEtab

	# - Magret, Front Motion Firefox
	Write-Host "      - Modèles > Magret > 10. Applications diverses > 10.3 FrontMotionFirefox Community Edition V3.05 > 10.3.1 Configuration navigateur"
	Write-Host "         @ Page d'accueil du collège : $URLEtab"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "Homepage" -Type String -value $URLEtab
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox\Homepage" -ValueName "Locked" -Type DWord -value 1
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox\Homepage" -ValueName "StartPage" -Type String -value "homepage"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox\Homepage" -ValueName "URL" -Type String -value $URLEtab
	Write-Host "      - Modèles > Magret > 10. Applications diverses > 10.3 FrontMotionFirefox Community Edition V3.05 > 10.3.2 Configuration du proxy"
	Write-Host "         @ Configuration manuelle : activée"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "ProxyType" -Type DWord -value 1
	Write-Host ("         @ Adresse IP:Port du proxy FTP, Gopher, HTTP, SOCKS, SSL : " + $IPProxy + ":3128")
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "ManualFTP" -Type String -value $IPProxy
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "ManualGopher" -Type String -value $IPProxy
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "ManualHTTP" -Type String -value $IPProxy
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "ManualSOCKS" -Type String -value $IPProxy
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "ManualSSL" -Type String -value $IPProxy
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "ManualFTPPort" -Type DWord -value 3128
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "ManualGopherPort" -Type DWord -value 3128
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "ManualHTTPPort" -Type DWord -value 3128
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "ManualSOCKSPort" -Type DWord -value 3128
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "ManualSSLPort" -Type DWord -value 3128
	Write-Host "         @ Exception du proxy : 10.*;<local>;$IPPronote"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox" -ValueName "ProxyExceptions" -Type String -value "10.*;<local>;$IPPronote"

	# - Google Chrome
	Write-Host "      - Modèles > Google"
	Write-Host ("         @ Adresse IP:Port du proxy : " + $IPProxy + ":3128")
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Google\Chrome" -ValueName "ProxyServer" -Type String -value ($IPProxy + ":3128")
	Write-Host "         @ Page d'accueil du collège : $URLEtab"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Google\Chrome" -ValueName "HomepageLocation" -Type String -value $URLEtab
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Google\Chrome\RestoreOnStartupURLs" -ValueName "1" -Type String -value $URLEtab

	# - Pronote dans la Default Domain Policy
	Write-Host "      - Modèles > Magret > 09. Modules pédagogiques MAGRET > 9.1 Fonctionnalités Magret Utilisateurs"
	Write-Host "         @ Affectation de la route pour l'adresse IP Pronote : $IPPronote,255.255.255.255,$IPRouteur"
	$tmp = Set-GPRegistryValue -Name "Default Domain Policy" -key "HKCU\Software\Policies\Magret\Routes" -ValueName "Route" -Type String -value "$IPPronote,255.255.255.255,$IPRouteur"
}


# Current as Ref
if ( $DoMakeCurrentAsRef ) {
	Write-Host ">> Positionnement des stratégies courantes en tant que référentiel ..."
	$rep = Read-Host -Prompt "  - Êtes-vous sûr de vouloir continuer (O/N) "
	if ( $rep -match "^o$" ) {
		$TimeStamp = ( Get-Date -format "yyyyMMddHHmmss" )
		$BackupPath = $rootPath + "\Backups\_tmp"
		Write-Host "  - Création des répertoires temporaires ..."
		$tmp = New-Item -ItemType directory -path "$BackupPath\Utilisateurs" -force
		$tmp = New-Item -ItemType directory -path "$BackupPath\Matériel" -force
		Write-Host "  - Sauvegarde des stratégies utilisateurs ..."
		$tmp = Backup-Gpo -Name "Utilisateurs" -Path "$BackupPath\Utilisateurs" -Comment ("Sauvegarde GPO Utilisateur " + $Domaine + " " + $TimeStamp)
		Write-Host "  - Sauvegarde des stratégies ordinateurs ..."
		$tmp = Backup-Gpo -Name "Matériel" -Path "$BackupPath\Matériel" -Comment ("Sauvegarde GPO Matériel " + $Domaine + " " + $TimeStamp)
		Write-Host "  - Remplacement du référentiel par les stratégies courantes :"
		Write-Host "  - Suppression du référentiel utilisateur ..."
		$tmp = Remove-Item -path "$rootPath\Referentiel\Utilisateurs" -Recurse -Force
		Write-Host "  - Suppression du référentiel ordinateur ..."
		$tmp = Remove-Item -path "$rootPath\Referentiel\Matériel" -Recurse -Force
		Write-Host "  - Déplacement des stratégies utilisateurs dans le référentiel ..."
		$tmp = Move-Item -Path "$BackupPath\Utilisateurs" -Destination "$rootPath\Referentiel\Utilisateurs"
		Write-Host "  - Déplacement des stratégies ordinateurs dans le référentiel ..."
		$tmp = Move-Item -Path "$BackupPath\Matériel" -Destination "$rootPath\Referentiel\Matériel"
		Write-Host "  - Suppression des répertoires temporaires ..."
		$tmp = Remove-Item -path "$BackupPath" -Recurse -Force
	}
}


Write-Host "`r`nTraitement terminé !`r`n"
Write-Host "------------------------------------------------------------------------`r`n"