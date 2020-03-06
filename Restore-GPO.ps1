<#
.SYNOPSIS
Outil de déploiement des stratégies de groupe CD31

.DESCRIPTION
Accompagné des fichiers modèles de stratégies et des stratégies de groupe
de référence, le script Restore-GPO.ps1 met-à-jour les modèles de stratégies,
sauvegarde les stratégies du collège et les remplace par les stratégies
de référence. Il permet aussi de modifier les valeurs propres au collège.
Enfin, il permet de remplacer les stratégies de référence par les stratégies
du collège, permettant ainsi de les restaurer rapidement.

Si des modifications sont effectuées dans l'établissement, elles peuvent
être sauvegardées et/ou devenir les stratégies de référence en utilisant
le paramètre **-MakeCurrentAsRef**.

Par défaut, ces étapes sont, dans l'ordre indiqué ci-dessus, toutes exécutées.
Avec les paramètres, chacune d'elles peut être désactivée. En utilisant la
combinaison suivante :
Restore-GPO.ps1 -URLEtab https://.../ -DisableMakeCurrentAsRef
le déploiement peut être automatisé.

Pour plus d'informations, dans le dossier ECOCD31-Restore-GPO exécuter :
Get-Help .\Restore-GPO.ps1 -full

Le dossier 'Backup' contient les sauvegardes horodatées, le dossier
'Referentiel' contient les stratégies de référence.
Le dossier 'PolicyDefinitions' contient les modèles de stratégies.
Le dossier 'Logs' contient les journaux des traitements.

Le déploiment de la configuration des scripts de démarrage - arrêt machine et
ouverture - fermeture de session utilisateur peut se faire en configurant
les scripts sur un collège équipé des stratégies de référence, avec les
outils microsoft. En remplaçant ensuite les stratégies de référence, ces
dernières ainsi que les fichiers liés peuvent être propagées pour mettre à jour
la configuration des scripts dans les autres collèges.


.PARAMETER URLEtab
L'adresse du site web du collège.

.PARAMETER VersionRef
Switch pour utiliser un autre référentiel que le dernier.

.PARAMETER BackupOnlyUser
Switch pour ne sauvegarder que les stratégies utilisateur du collège.
Inactif si -DisableBackupCurrentGPO est utilisé.
.PARAMETER BackupOnlyMachine
Switch pour ne sauvegarder que les stratégies machine du collège.
Inactif si -DisableBackupCurrentGPO est utilisé.

.PARAMETER DisableDeploySchema
Switch pour désactiver la mise-à-jour des fichiers modèles de stratégies.
.PARAMETER DisableBackupCurrentGPO
Switch pour désactiver la sauvegarde des stratégies du collège.
.PARAMETER DisableRestoreRefGPO
Switch pour désactiver la restauration des stratégies de référence.
.PARAMETER DisablePatchValues
Switch pour désactiver le questionnaire et la modification
des valeurs propres au collège.
.PARAMETER DisableMakeCurrentAsRef
Switch pour désactiver le remplacement des stratégies de référence par les stratégies du collège.

.PARAMETER MakeCurrentAsRef
Switch qui désactive tous les traitements sauf le remplacement
des stratégies de référence par les stratégies du collège.
Equivalent à utiliser tous les paramètres
de désactivation -Disable... sauf -DisableMakeCurrentAsRef.


.NOTES

Version :
Voir le fichier Doc/version.txt
Emmanuel Fournier
mailto:emmanuel.fournier@econocom.com

Paramètres :
Les paramètres communs ne sont pas pris en charge par ce script.

TODO :
- Patcher "Default Domain Controllers Policy" pour interdire l'ouverture
d'une session locale pour Adminsta; G_Modele; G_Profs; G_Eleves; G_Pad.


.LINK
    https://github.com/manoletto/ECOCD31-Restore-GPO


.INPUTS
Ce script ne gère aucun objet reçus en entrée.

.OUTPUTS
Ce script ne génère aucun objet en sortie.
#>


#requires -version 2


# --------------------------------------------------------------------------------------------
# Init
# --------------------------------------------------------------------------------------------

[CmdletBinding()]
param(
	[Parameter(Mandatory=$False)] [string]$URLEtab,
	[Parameter(Mandatory=$False)] [string]$VersionRef,
	[Parameter(Mandatory=$False)] [switch]$BackupOnlyUser,
	[Parameter(Mandatory=$False)] [switch]$BackupOnlyMachine,
	[Parameter(Mandatory=$False)] [switch]$DisableDeploySchema,
	[Parameter(Mandatory=$False)] [switch]$DisableBackupCurrentGPO,
	[Parameter(Mandatory=$False)] [switch]$DisableRestoreRefGPO,
	[Parameter(Mandatory=$False)] [switch]$DisablePatchValues,
	[Parameter(Mandatory=$False)] [switch]$DisableMakeCurrentAsRef,
	[Parameter(Mandatory=$False)] [switch]$MakeCurrentAsRef
)



# Version
$RGPOVersion = "1.4"


$ErrorActionPreference = 'Continue'
$rootPath = (Split-Path $script:MyInvocation.MyCommand.Path)+"\"
$CurrentScriptName = (Get-Item $PSCommandPath).Basename




# --------------------------------------------------------------------------------------------
# Fonctions
# --------------------------------------------------------------------------------------------

. $rootPath\Libs\ToolsBox-Library.ps1




# --------------------------------------------------------------------------------------------
# Paramètres systèmes
# --------------------------------------------------------------------------------------------

# Pour forcer l'activation ou désactivation des sous-traitements
$ForceDisableDeploySchema = $False
$ForceDisableBackupCurrentGPO = $False
$ForceDisableRestoreRefGPO = $False
$ForceDisablePatchValues = $False
$ForceDisableMakeCurrentAsRef = $False

# Fichier journal
$TimeStamp = ( Get-Date -format "yyyyMMddHHmmss" )
$LogFile = $rootPath + "Logs\" + $CurrentScriptName + "_" + $Domaine + "_" + $TimeStamp + '.log'




# --------------------------------------------------------------------------------------------
# Traitement
# --------------------------------------------------------------------------------------------


# Affichage intro
Clear-Host
Audit "Traitement des GPOs v$RGPOVersion"
Audit "------------------------------------------------------------------------"


WOEnv


# Controle traitement sur Serveur01
if ( $Hostname -ne "SERVEUR01" ) {
	Audit "Veuillez exécuter ce script sur le serveur01 !" "ERROR" 1
}


# Erreur lecture adresse IP
if ( $IPserver -notmatch "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$" ) {
	Audit "Impossible de lire l'adresse IP de cette machine !" "ERROR" 2
}


# Au final, est-ce qu'on effectue les traitements
$DoDeploySchema = $ForceDisableDeploySchema -eq $False -and $DisableDeploySchema -eq $False -and $MakeCurrentAsRef -eq $False
$DoBackupCurrentGPO = $ForceDisableBackupCurrentGPO -eq $False -and $DisableBackupCurrentGPO -eq $False -and $MakeCurrentAsRef -eq $False
$DoRestoreRefGPO = $ForceDisableRestoreRefGPO -eq $False -and $DisableRestoreRefGPO -eq $False -and $MakeCurrentAsRef -eq $False
$DoPatchValues = $ForceDisablePatchValues -eq $False -and $DisablePatchValues -eq $False -and $MakeCurrentAsRef -eq $False
$DoMakeCurrentAsRef = $ForceDisableMakeCurrentAsRef -eq $False -and $DisableMakeCurrentAsRef -eq $False
# Aucun traitement actif : fin du script !
if ( $DoDeploySchema -eq $False -and $DoBackupCurrentGPO -eq $False -and $DoRestoreRefGPO -eq $False -and $DoPatchValues -eq $False -and $DoMakeCurrentAsRef -eq $False ) {
	Audit "Aucun traitement n'est activé ... !?" "WARNING" 3
}


# Déploiement du schéma
if ( $DoDeploySchema ) {
	Audit ">> Déploiement du schéma ..."

	# Si le répertoire PolicyDefinitions n'existe pas, on le créé :
	If ( ( Test-Path "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\PolicyDefinitions\" ) -ne $true ) {
		Audit "  - Création des répertoires ..."
	    $tmp = New-Item -path "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\PolicyDefinitions" -ItemType directory
	    $tmp = New-Item -path "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\PolicyDefinitions\fr-FR\" -ItemType directory
	}
	# Mise en place des modèles de stratégies :
	If ( ( Test-Path "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\PolicyDefinitions\" ) -eq $true ) {
		Audit "  - Mise en place des modèles de stratégies ..."
		Copy-Item "$rootPath\PolicyDefinitions" -Destination "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\" -Recurse -force
	}
}


# Sauvegarde des GPO
if ( $DoBackupCurrentGPO ) {
	Audit ">> Sauvegarde des stragégies en service ..."
	$TimeStamp = ( Get-Date -format "yyyyMMddHHmmss" )
	$BackupPath = $rootPath + "\Backups\GpoBackups_" + $Domaine + "_" + $TimeStamp

	if ( $BackupOnlyMachine -eq $False -or $BackupOnlyUser -eq $True ) {
		Audit "  - Création du répertoire pour la sauvegarde utilisateur ..."
		$tmp = New-Item -ItemType directory -path "$BackupPath\Utilisateurs" -force
		Audit "  - Sauvegarde des stratégies utilisateurs ..."
		$tmp = Backup-Gpo -Name "Utilisateurs" -Path "$BackupPath\Utilisateurs" -Comment ("Sauvegarde GPO Utilisateur " + $Domaine + " " + $TimeStamp)
	}
	if ( $BackupOnlyUser -eq $False -or $BackupOnlyMachine -eq $True ) {
		Audit "  - Création du répertoire pour la sauvegarde ordinateur ..."
		$tmp = New-Item -ItemType directory -path "$BackupPath\Matériel" -force
		Audit "  - Sauvegarde des stratégies ordinateurs ..."
		$tmp = Backup-Gpo -Name "Matériel" -Path "$BackupPath\Matériel" -Comment ("Sauvegarde GPO Matériel " + $Domaine + " " + $TimeStamp)
	}
}


# Importation des nouveaux paramètres dans les GPO (les anciens contenus seront écrasés !)
if ( $DoRestoreRefGPO ) {
	Audit ">> Activation des stratégies de référence ..."
	if ( $VersionRef -ne "" ) {
		if ( ( Test-Path "$rootPath\Referentiel\$VersionRef\Utilisateurs" ) -ne $true ) {
			Audit "La version $VersionRef est introuvable !"
		}else{
			Audit "  - Importation des stratégies utilisateurs ..."
			$tmp = Import-Gpo -BackupGpoName "Utilisateurs" -TargetName "Utilisateurs" -path "$rootPath\Referentiel\$VersionRef\Utilisateurs" -CreateIfNeeded
			Audit "  - Importation des stratégies ordinateurs ..."
			$tmp = Import-Gpo -BackupGpoName "Matériel" -TargetName "Matériel" -path "$rootPath\Referentiel\$VersionRef\Matériel" -CreateIfNeeded
		}
	}else{
		Audit "  - Importation des stratégies utilisateurs ..."
		$tmp = Import-Gpo -BackupGpoName "Utilisateurs" -TargetName "Utilisateurs" -path "$rootPath\Referentiel\Last\Utilisateurs" -CreateIfNeeded
		Audit "  - Importation des stratégies ordinateurs ..."
		$tmp = Import-Gpo -BackupGpoName "Matériel" -TargetName "Matériel" -path "$rootPath\Referentiel\Last\Matériel" -CreateIfNeeded
	}
}


# Adaptation des valeurs
if ( $DoPatchValues ) {
	Audit ">> Personnalisation des valeurs du site ..."

	# URL du site du collège
	while ( $URLEtab -notmatch "^http[s]?://" ) {
		$URLEtab = Read-Host -Prompt "  - Quelle est l'adresse du site web de l'établissement (ex : https:// ...) "
	}

	# Extraction du RNE depuis le domaine
	$tmp = $Domaine -cmatch "^COL-(\d{7}[A-Z])\d{2}$"
	$RNEEtab = $Matches.1
	Audit "  - RNE de l'établissement : $RNEEtab"

	# Avec le RNE, ping sur RNE.index-education.net pour récupération de l'@IP Pronote
	if ( Test-Connection -ComputerName $RNEEtab".index-education.net" -Count 1 -Quiet ) {
		$IPPronote = (Test-Connection -ComputerName $RNEEtab".index-education.net" -Count 1).IPV4Address.ToString()
		Audit "  - Adresse IP Pronote : $IPPronote"
	}else{
		Audit "  - Aucune adresse IP Pronote relevée pour le nom $RNEEtab.index-education.net !"
		$IPPronote = ""
		while ( $IPPronote -notmatch "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$" ) {
			$IPPronote = Read-Host -Prompt "  - Quelle est l'adresse IPv4 Pronote (ex : 46.33.154.23) "
		}
	}

	# Construction adresse IP Serveur01 depuis l'adresse du proxy
	Audit "  - Adresse IP Serveur01 : $IPserver"
	$octs = $IPserver -split "\."
	$prefixIP = $octs[0] + "." + $octs[1] + "." + $octs[2] + "."
	$IPRouteur = $prefixIP + ([int]$octs[3] + 1)
	Audit "  - Adresse IP PFS : $IPRouteur"
	$IPProxy = $prefixIP + ([int]$octs[3] - 1)
	Audit "  - Adresse IP Proxy : $IPProxy"


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
	Audit ">> Sauvegarde des valeurs du site dans les stratégies de groupe du système ..."
	Audit "  - Matériel"
	Audit "    - Stratégies"

	# - Magret, Serveur3
	Audit "      - Modèles > Magret > 7. Application MAGRET > 7.1 Paramètres du serveur MAGRET"
	Audit "         @ IP du serveur MAGRET : $IPserver"
	$tmp = Set-GPRegistryValue -Name "Matériel" -key "HKLM\Software\Magret" -ValueName "IPServeurMagret" -Type String -value $IPserver
	Audit "         @ Nom du domaine MAGRET : $Domaine"
	$tmp = Set-GPRegistryValue -Name "Matériel" -key "HKLM\Software\Magret" -ValueName "DomaineMagret" -Type String -value $Domaine
	Audit "         @ Nom du serveur MAGRET : \\SERVEUR01"
	$tmp = Set-GPRegistryValue -Name "Matériel" -key "HKLM\Software\Magret" -ValueName "ServeurMagret" -Type String -value "\\SERVEUR01"
	# - Magret, Proxy
	Audit "      - Modèles > Magret > 4. Réseau et Accès distant"
	Audit ("         @ Serveur proxy pour les applications Window 8.1 et 10 : " + $IPProxy + ":3128")
	$tmp = Set-GPRegistryValue -Name "Matériel" -key "HKLM\Software\Policies\Microsoft\Windows\NetworkIsolation" -ValueName "DomainProxies" -Type String -value ($IPProxy + ":3128")


	# >>> Utilisateurs <<<
	Audit "  - Utilisateurs"
	Audit "    - Stratégies"

	# - Composants Windows, Edge
	Audit "      - Modèles > Composants Windows > Microsoft Edge"
	Audit "         @ Page d'accueil du collège : $URLEtab"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Microsoft\MicrosoftEdge\Internet Settings" -ValueName "ProvisionedHomePages" -Type String -value "<$URLEtab>"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Microsoft\MicrosoftEdge\Internet Settings" -ValueName "ConfigureHomeButton" -Type DWord -value 2
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Microsoft\MicrosoftEdge\Internet Settings" -ValueName "HomeButtonURL" -Type String -value "$URLEtab"

	# - Magret, Internet Explorer
	Audit "      - Modèles > Magret > 8. Composants Windows > 8.10 Internet Explorer"
	Audit "         @ Activation du proxy : activée"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName "ProxyEnable" -Type DWord -value 1
	Audit ("         @ Adresse IP:Port du proxy : " + $IPProxy + ":3128")
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName "ProxyServer" -Type String -value ($IPProxy + ":3128")
	Audit "         @ Exception du proxy : 10.*;<local>;$IPPronote"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName "ProxyOverride" -Type String -value "10.*;<local>;$IPPronote"
	Audit "         @ Page d'accueil du collège : $URLEtab"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Microsoft\Internet Explorer\Main" -ValueName "Start Page" -Type String -value $URLEtab

	# - Composants Windows, Internet Explorer
	Audit "      - Modèles > Composants Windows > Internet Explorer"
	Audit "         @ Désactiver la modification de la page d'accueil : activée"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Microsoft\Internet Explorer\Main" -ValueName "Start Page" -Type String -value $URLEtab

	# - Firefox ESR
	Audit "      - Modèles > Mozilla > Firefox"
	Audit "         @ Page d'accueil du collège : $URLEtab"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox\Homepage" -ValueName "Locked" -Type DWord -value 1
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox\Homepage" -ValueName "StartPage" -Type String -value "homepage"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox\Homepage" -ValueName "URL" -Type String -value $URLEtab
	Audit "         @ Paramètres du proxy"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox\Proxy" -ValueName "Mode" -Type String -value "system"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Mozilla\Firefox\Proxy" -ValueName "Passthrough" -Type String -value "10.0.0.0/8, $IPPronote"

	# - Google Chrome
	Audit "      - Modèles > Google"
	Audit ("         @ Adresse IP:Port du proxy : " + $IPProxy + ":3128")
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Google\Chrome" -ValueName "ProxyServer" -Type String -value ($IPProxy + ":3128")
	Audit "         @ Page d'accueil du collège : $URLEtab"
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Google\Chrome" -ValueName "HomepageLocation" -Type String -value $URLEtab
	$tmp = Set-GPRegistryValue -Name "Utilisateurs" -key "HKCU\Software\Policies\Google\Chrome\RestoreOnStartupURLs" -ValueName "1" -Type String -value $URLEtab

	# - Pronote dans la Default Domain Policy
	Audit "      - Modèles > Magret > 09. Modules pédagogiques MAGRET > 9.1 Fonctionnalités Magret Utilisateurs"
	Audit "         @ Affectation de la route pour l'adresse IP Pronote : $IPPronote,255.255.255.255,$IPRouteur"
	$tmp = Set-GPRegistryValue -Name "Default Domain Policy" -key "HKCU\Software\Policies\Magret\Routes" -ValueName "Route" -Type String -value "$IPPronote,255.255.255.255,$IPRouteur"
}


# Remplacement des stratégies de référence par les stratégies du collège
if ( $DoMakeCurrentAsRef ) {
	Audit ">> Remplacement des stratégies de référence par les stratégies du collège ..."
	$rep = Read-Host -Prompt "  - Êtes-vous sûr de vouloir continuer (O/N) "
	if ( $rep -match "^o$" ) {
		$TimeStamp = ( Get-Date -format "yyyyMMddHHmmss" )
		$BackupPath = $rootPath + "\Backups\_tmp"
		Audit "  - Création des répertoires temporaires ..."
		$tmp = New-Item -ItemType directory -path "$BackupPath\Utilisateurs" -force
		$tmp = New-Item -ItemType directory -path "$BackupPath\Matériel" -force
		Audit "  - Sauvegarde des stratégies utilisateurs du collège ..."
		$tmp = Backup-Gpo -Name "Utilisateurs" -Path "$BackupPath\Utilisateurs" -Comment ("Sauvegarde GPO Utilisateur " + $Domaine + " " + $TimeStamp)
		Audit "  - Sauvegarde des stratégies ordinateurs du collège ..."
		$tmp = Backup-Gpo -Name "Matériel" -Path "$BackupPath\Matériel" -Comment ("Sauvegarde GPO Matériel " + $Domaine + " " + $TimeStamp)
		Audit "  - Suppression des stratégies de référence utilisateur ..."
		$tmp = Remove-Item -path "$rootPath\Referentiel\Last\Utilisateurs" -Recurse -Force
		Audit "  - Suppression des stratégies de référence ordinateur ..."
		$tmp = Remove-Item -path "$rootPath\Referentiel\Last\Matériel" -Recurse -Force
		Audit "  - Déplacement des stratégies utilisateurs du collège dans le référentiel ..."
		$tmp = Move-Item -Path "$BackupPath\Utilisateurs" -Destination "$rootPath\Referentiel\Last\Utilisateurs"
		Audit "  - Déplacement des stratégies ordinateurs du collège dans le référentiel ..."
		$tmp = Move-Item -Path "$BackupPath\Matériel" -Destination "$rootPath\Referentiel\Last\Matériel"
		Audit "  - Suppression des répertoires temporaires ..."
		$tmp = Remove-Item -path "$BackupPath" -Recurse -Force
	}else{
		Audit "  - Opération annulée par l'utilisateur." "LOG"
	}
}

Write-Output ""
Audit "Traitement terminé !"
Audit "------------------------------------------------------------------------`r`n"