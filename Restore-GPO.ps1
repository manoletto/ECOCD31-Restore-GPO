<#
.SYNOPSIS
Outil de déploiement des stratégies de groupe 'Matériel' et 'Utilisateurs' CD31

.DESCRIPTION
Accompagné des fichiers modèles de stratégies et des stratégies de groupe
de référence 'Matériel' et 'Utilisateurs', le script Restore-GPO.ps1
met-à-jour les modèles de stratégies, sauvegarde les stratégies 'Matériel' et
'Utilisateurs' du collège et les remplace par les stratégies de référence. Il permet
aussi de modifier les valeurs propres au collège.
Enfin, il permet de remplacer les stratégies de référence 'Matériel' et 'Utilisateurs'
par les stratégies 'Matériel' et 'Utilisateurs' du collège, permettant ainsi de les restaurer rapidement.

Différentes versions des stratégies de référence peuvent être utilisées. Lors de l'activation
des stratégies de référence et du remplacement des stratégies de référence par celles du collège,
la "dernière" version est utilisée par défaut. Sauf à utiliser respectivement les paramètres
-RestoreRefGPOVersion et -MakeCurrentAsRefVersion.
Chaque version est stockée dans un sous-dossier du dossier 'Referentiel'.
Les noms de version 'v1' et 'Last' sont réservés.

Si des modifications sont effectuées sur les stratégies 'Matériel' et 'Utilisateurs' dans
l'établissement, elles peuvent devenir les stratégies de référence en utilisant
le paramètre -MakeCurrentAsRef.

Par défaut, ces étapes, sauf le remplacement des stratégies de référence,
sont, dans l'ordre indiqué ci-dessus, toutes exécutées.
Avec les paramètres de commande, chacune d'elles peut être désactivée.

En utilisant la commande suivante :
	Restore-GPO.ps1
le déploiement peut être automatisé.

Pour plus d'informations, dans le dossier ECOCD31-Restore-GPO exécuter :
	Get-Help .\Restore-GPO.ps1 -full

Le dossier 'Backup' contient les sauvegardes horodatées, le dossier
'Referentiel' contient les stratégies de référence.
Le dossier 'PolicyDefinitions' contient les modèles de stratégies.
Le dossier 'Logs' contient les journaux des traitements.


.PARAMETER URLEtab
L'adresse du site web du collège est normalement automatiquement définie.
Ce paramètre permet de choisir une autre URL.

.PARAMETER RestoreRefGPOVersion
Lors de l'activation des stratégies de référence, ce paramètre permet d'indiquer la version à utiliser.
Par défaut, la dernière version est utilisée.
Inactif si -DisableRestoreRefGPO est utilisé.

.PARAMETER UpdateUserTo
Ce paramètre permet d'indiquer un nom d'objet GPO différent de "Utilisateurs"
pour la sauvegarde et pour l'activation des stratégies de référence.
.PARAMETER UpdateMachineTo
Ce paramètre permet d'indiquer un nom d'objet GPO différent de "Matériel"
pour la sauvegarde et pour l'activation des stratégies de référence.

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
Switch pour désactiver le questionnaire et la modification des valeurs propres au collège.

.PARAMETER MakeCurrentAsRef
Switch qui désactive tous les traitements et effectue le remplacement
des stratégies de référence par les stratégies du collège.

.PARAMETER MakeCurrentAsRefUserWith
Lors du remplacement des stratégies de référence par celles du collège,
ce paramètre permet d'indiquer un objet GPO existant différent de "Utilisateurs",
à utiliser comme source.
Inactif si -MakeCurrentAsRef n'est pas utilisé.
.PARAMETER MakeCurrentAsRefMachineWith
Lors du remplacement des stratégies de référence par celles du collège,
ce paramètre permet d'indiquer un objet GPO existant différent de "Matériel",
à utiliser comme source.
Inactif si -MakeCurrentAsRef n'est pas utilisé.

.PARAMETER MakeCurrentAsRefVersion
Lors du remplacement des stratégies de référence par celles du collège,
ce paramètre permet d'indiquer la version à remplacer.
Par défaut, la dernière version est remplacée.
Inactif si -MakeCurrentAsRef n'est pas utilisé.

.PARAMETER ShowOnly
Ce paramètre montre le traitement sans effectuer aucune modification.
Il désactive l'enregistrement dans le journal de traitement.


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

param(
	[Parameter(Position=1,Mandatory=$False)] [string]$URLEtab,
	[Parameter(Position=2,Mandatory=$False)] [string]$IPPronote,
	[Parameter(Position=3,Mandatory=$False)] [string]$IPServer01,
	[Parameter(Position=4,Mandatory=$False)] [string]$RestoreRefGPOVersion,
	[Parameter(Position=5,Mandatory=$False)] [string]$UpdateUserTo,
	[Parameter(Position=6,Mandatory=$False)] [string]$UpdateMachineTo,
	[Parameter(Position=7,Mandatory=$False)] [switch]$BackupOnlyUser,
	[Parameter(Position=8,Mandatory=$False)] [switch]$BackupOnlyMachine,
	[Parameter(Position=9,Mandatory=$False)] [switch]$DisableDeploySchema,
	[Parameter(Position=10,Mandatory=$False)] [switch]$DisableBackupCurrentGPO,
	[Parameter(Position=11,Mandatory=$False)] [switch]$DisableRestoreRefGPO,
	[Parameter(Position=12,Mandatory=$False)] [switch]$DisablePatchValues,
	[Parameter(Position=13,Mandatory=$False)] [switch]$MakeCurrentAsRef,
	[Parameter(Position=14,Mandatory=$False)] [string]$MakeCurrentAsRefUserWith,
	[Parameter(Position=15,Mandatory=$False)] [string]$MakeCurrentAsRefMachineWith,
	[Parameter(Position=16,Mandatory=$False)] [string]$MakeCurrentAsRefVersion,
	[Parameter(Position=17,Mandatory=$False)] [switch]$ShowOnly
)



# Version
$RGPOVersion = "1.6"


$ErrorActionPreference = 'Continue'
$rootPath = (Split-Path $script:MyInvocation.MyCommand.Path)+"\"
$CurrentScriptName = (Get-Item $PSCommandPath).Basename




# --------------------------------------------------------------------------------------------
# Fonctions
# --------------------------------------------------------------------------------------------

. $rootPath\Libs\ToolsBox-Library.ps1
#. $rootPath\Libs\GPFunctions.ps1



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

# Traitement à blanc
$AuditNoLog = $ShowOnly
$Show = $ShowOnly




# --------------------------------------------------------------------------------------------
# Traitement
# --------------------------------------------------------------------------------------------


# Affichage intro
Clear-Host
if ( $Show ) {
	Audit "Traitement à blanc des GPOs v$RGPOVersion"
}else{
	Audit "Traitement des GPOs v$RGPOVersion"
}
Audit "------------------------------------------------------------------------"


WOEnv


# Controle traitement sur Serveur01
if ( $Hostname -ne "SERVEUR01" ) {
	Audit "Veuillez exécuter ce script sur le serveur01 !" "ERROR" 1
}


# Erreur lecture adresse IP
if ( $IPserver01 -ne "" -and $IPserver01 -notmatch "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$" ) {
	Audit "L'adresse IP fournie n'est pas correcte !" "ERROR" 2
}


# Au final, est-ce qu'on effectue les traitements
$DoDeploySchema = $ForceDisableDeploySchema -eq $False -and $DisableDeploySchema -eq $False -and $MakeCurrentAsRef -eq $False
$DoBackupCurrentGPO = $ForceDisableBackupCurrentGPO -eq $False -and $DisableBackupCurrentGPO -eq $False -and $MakeCurrentAsRef -eq $False
$DoRestoreRefGPO = $ForceDisableRestoreRefGPO -eq $False -and $DisableRestoreRefGPO -eq $False -and $MakeCurrentAsRef -eq $False
$DoPatchValues = $ForceDisablePatchValues -eq $False -and $DisablePatchValues -eq $False -and $MakeCurrentAsRef -eq $False
$DoMakeCurrentAsRef = $ForceDisableMakeCurrentAsRef -eq $False -and $MakeCurrentAsRef -eq $True
# Aucun traitement actif : fin du script !
if ( $DoDeploySchema -eq $False -and $DoBackupCurrentGPO -eq $False -and $DoRestoreRefGPO -eq $False -and $DoPatchValues -eq $False -and $DoMakeCurrentAsRef -eq $False ) {
	Audit "Aucun traitement n'est activé ... !?" "WARNING" 3
}


# Déploiement du schéma
if ( $DoDeploySchema ) {
	Audit ">> Déploiement du schéma ..."

	# Si le répertoire PolicyDefinitions n'existe pas, on le créé :
	If ( ( Test-Path "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\PolicyDefinitions\" ) -ne $true ) {
		Audit "  - Création des répertoires PolicyDefinitions ..."
		if ( $Show -ne $True ) {
		    $tmp = New-Item -path "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\PolicyDefinitions" -ItemType directory
		    $tmp = New-Item -path "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\PolicyDefinitions\fr-FR\" -ItemType directory
	    }
	}
	# Mise en place des modèles de stratégies :
	If ( ( Test-Path "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\PolicyDefinitions\" ) -eq $true ) {
		Audit "  - Mise en place des modèles de stratégies ..."
		if ( $Show -ne $True ) {
			Copy-Item "$rootPath\PolicyDefinitions" -Destination "\\serveur01\c$\windows\SYSVOL\sysvol\$DomaineDNS\Policies\" -Recurse -force
		}
	}
}


# Noms des objets GPO à sauvegader
if ( $UpdateUserTo -eq "" ) {
	$UserSrcBackupGPOName = "Utilisateurs"
}else{
	$UserSrcBackupGPOName = $UpdateUserTo
}
if ( $UpdateMachineTo -eq "" ) {
	$MachineSrcBackupGPOName = "Matériel"
}else{
	$MachineSrcBackupGPOName = $UpdateMachineTo
}

# Sauvegarde des GPO
if ( $DoBackupCurrentGPO ) {
	Audit ">> Sauvegarde des stragégies en service ..."
	$TimeStamp = ( Get-Date -format "yyyyMMddHHmmss" )
	$BackupPath = $rootPath + "\Backups\GpoBackups_" + $Domaine + "_" + $TimeStamp

	if ( $BackupOnlyMachine -eq $False -or $BackupOnlyUser -eq $True ) {
		if ( Check-GPO "$UserSrcBackupGPOName" ) {
			Audit "  - Création du répertoire pour la sauvegarde utilisateur ..."
			if ( $Show -ne $True ) {
				$tmp = New-Item -ItemType directory -path "$BackupPath\Utilisateurs" -force
			}
			Audit "  - Sauvegarde des stratégies utilisateurs ..."
			if ( $Show -ne $True ) {
				$tmp = Backup-Gpo -Name "$UserSrcBackupGPOName" -Path "$BackupPath\Utilisateurs" -Comment ("Sauvegarde GPO '" + $UserSrcBackupGPOName + "' " + $Domaine + " " + $TimeStamp)
			}
		}else{
			Audit "  L'objet GPO utilisateurs '$UserSrcBackupGPOName' n'existe pas !" "WARNING"
		}
	}
	if ( $BackupOnlyUser -eq $False -or $BackupOnlyMachine -eq $True ) {
		if ( Check-GPO "$MachineSrcBackupGPOName" ) {
			Audit "  - Création du répertoire pour la sauvegarde ordinateur ..."
			if ( $Show -ne $True ) {
				$tmp = New-Item -ItemType directory -path "$BackupPath\Matériel" -force
			}
			Audit "  - Sauvegarde des stratégies ordinateurs ..."
			if ( $Show -ne $True ) {
				$tmp = Backup-Gpo -Name "$MachineSrcBackupGPOName" -Path "$BackupPath\Matériel" -Comment ("Sauvegarde GPO '" + $MachineSrcBackupGPOName + "' " + $Domaine + " " + $TimeStamp)
			}
		}else{
			Audit "  L'objet GPO matériel '$MachineSrcBackupGPOName' n'existe pas !" "WARNING"
		}
	}
}


# Noms des objets GPO à sauvegader
if ( $UpdateUserTo -eq "" ) {
	$UserDestGPOName = "Utilisateurs"
}else{
	$UserDestGPOName = $UpdateUserTo
}
if ( $UpdateMachineTo -eq "" ) {
	$MachineDestGPOName = "Matériel"
}else{
	$MachineDestGPOName = $UpdateMachineTo
}

# Importation des nouveaux paramètres dans les GPO (les anciens contenus seront écrasés !)
if ( $DoRestoreRefGPO ) {
	if ( $RestoreRefGPOVersion -ne "" ) {
		Audit ">> Activation des stratégies de référence [version $RestoreRefGPOVersion] ..."
		if ( ( Test-Path "$rootPath\Referentiel\$RestoreRefGPOVersion\Utilisateurs" ) -ne $true ) {
			Audit "La version $RestoreRefGPOVersion est introuvable !"
		}else{
			Audit "  - Importation des stratégies de référence utilisateurs dans '$UserDestGPOName' ..."
			if ( $Show -ne $True ) {
				$tmp = Import-Gpo -BackupGpoName "Utilisateurs" -TargetName "$UserDestGPOName" -path "$rootPath\Referentiel\$RestoreRefGPOVersion\Utilisateurs" -CreateIfNeeded
			}
			Audit "  - Importation des stratégiesde référence matériel dans '$MachineDestGPOName' ..."
			if ( $Show -ne $True ) {
				$tmp = Import-Gpo -BackupGpoName "Matériel" -TargetName "$MachineDestGPOName" -path "$rootPath\Referentiel\$RestoreRefGPOVersion\Matériel" -CreateIfNeeded
			}
		}
	}else{
		Audit ">> Activation des stratégies de référence [version Last] ..."
		Audit "  - Importation des stratégies de référence utilisateurs dans '$UserDestGPOName' ..."
		if ( $Show -ne $True ) {
			$tmp = Import-Gpo -BackupGpoName "Utilisateurs" -TargetName "$UserDestGPOName" -path "$rootPath\Referentiel\Last\Utilisateurs" -CreateIfNeeded
		}
		Audit "  - Importation des stratégies de référence matériel dans '$MachineDestGPOName' ..."
		if ( $Show -ne $True ) {
			$tmp = Import-Gpo -BackupGpoName "Matériel" -TargetName "$MachineDestGPOName" -path "$rootPath\Referentiel\Last\Matériel" -CreateIfNeeded
		}
	}
}


# Adaptation des valeurs
if ( $DoPatchValues ) {
	Audit ">> Personnalisation des valeurs du site ..."

	# Extraction du RNE depuis le domaine
	$tmp = $Domaine -cmatch "^COL-(\d{7}[A-Z])(\d{2})$"
	$RNEEtab = $Matches.1
	Audit "  - RNE de l'établissement : $RNEEtab"

	# RNE pour la recherche de l'URL
	$RNEUrl = $RNEEtab
	if ( $Matches.2 -ne "01" ) {
		$RNEUrl = $RNEUrl + "_" + [int]$Matches.2
	}

	# URL du site du collège
	if ( $URLEtab -eq "" ) {
		# Lecture du fichier de configuration des URLs
		$DomainURLs = Import-Csv -Path ( $rootPath + "\Conf\rne_url.csv" ) -Delimiter ";" | Sort-Object Domain
		# Recherche de l'URL du collège
		$URLEtab = $DomainURLs | Where-Object ({$_.rne -Match $RNEUrl}) | Select-Object -ExpandProperty url
		if ( $URLEtab -eq "" ) {
			Audit "    Le RNE du collège est introuvable dans le fichier de configuration des URLs !" "WARNING"
			while ( $URLEtab -notmatch "^http[s]?://" ) {
				$URLEtab = Read-Host -Prompt "  - Quelle est l'adresse du site web de l'établissement (ex : https:// ...) "
			}
		}
	}
	Audit "  - Adresse du site web de l'établissement : $URLEtab"

	# Adresse IP Pronote
	if ( $IPPronote -eq "" ) {
		# Avec le RNE, ping sur RNE.index-education.net pour récupération de l'@IP Pronote
		if ( Test-Connection -ComputerName $RNEEtab".index-education.net" -Count 1 -Quiet ) {
			$IPPronote = (Test-Connection -ComputerName $RNEEtab".index-education.net" -Count 1).IPV4Address.ToString()
			Audit "  - Adresse IP Pronote : $IPPronote"
		}else{
			Audit "  - Aucune adresse IP Pronote relevée pour le nom $RNEEtab.index-education.net !"
			$IPPronote = ""
		}
	}else{
		Audit "  - Adresse IP Pronote : $IPPronote"
	}

	# Adresse IP Serveur01
	if ( $IPServer01 -eq "" ) {
		if ( $IPserver.Count -eq 1 ) {
			$IPServer01 = $IPserver
		}else{
			Audit "  - Ce serveur possède plusieurs adresses IP ..." "WARNING"
			For ($i=0; $i -lt $IPserver.Count; $i++) {
				$CurSrvIP = $IPserver[$i]
				Audit "      [$i] - $CurSrvIP"
			}
			$IdxChoosenIP = "NO"
			while ( $IdxChoosenIP -notmatch "^\d+$" -or !$IPserver[$IdxChoosenIP] ) {
				$IdxChoosenIP = Read-Host -Prompt "    Veuillez en choisir une par son numéro (0,1, ...) "
			}
			$IPServer01 = $IPserver[$IdxChoosenIP]
		}
	}

	# Construction adresse IP routeur et proxy depuis l'adresse du Serveur01
	Audit "  - Adresse IP Serveur01 : $IPserver01"
	$octs = $IPserver01 -split "\."
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
	Audit "         @ IP du serveur MAGRET : $IPserver01"
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$MachineDestGPOName" -key "HKLM\Software\Magret" -ValueName "IPServeurMagret" -Type String -value $IPserver01
	}
	Audit "         @ Nom du domaine MAGRET : $Domaine"
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$MachineDestGPOName" -key "HKLM\Software\Magret" -ValueName "DomaineMagret" -Type String -value $Domaine
	}
	Audit "         @ Nom du serveur MAGRET : \\SERVEUR01"
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$MachineDestGPOName" -key "HKLM\Software\Magret" -ValueName "ServeurMagret" -Type String -value "\\SERVEUR01"
	}
	# - Magret, Proxy
	Audit "      - Modèles > Magret > 4. Réseau et Accès distant"
	Audit ("         @ Serveur proxy pour les applications Window 8.1 et 10 : " + $IPProxy + ":3128")
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$MachineDestGPOName" -key "HKLM\Software\Policies\Microsoft\Windows\NetworkIsolation" -ValueName "DomainProxies" -Type String -value ($IPProxy + ":3128")
	}


	# >>> Utilisateurs <<<
	Audit "  - Utilisateurs"
	Audit "    - Stratégies"

	# - Composants Windows, Edge
	Audit "      - Modèles > Composants Windows > Microsoft Edge"
	Audit "         @ Page d'accueil du collège : $URLEtab"
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Microsoft\MicrosoftEdge\Internet Settings" -ValueName "ProvisionedHomePages" -Type String -value "<$URLEtab>"
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Microsoft\MicrosoftEdge\Internet Settings" -ValueName "ConfigureHomeButton" -Type DWord -value 2
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Microsoft\MicrosoftEdge\Internet Settings" -ValueName "HomeButtonURL" -Type String -value "$URLEtab"
	}

	# - Magret, Internet Explorer
	Audit "      - Modèles > Magret > 8. Composants Windows > 8.10 Internet Explorer"
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName "ProxyEnable" -Type DWord -value 1
	}
	Audit ("         @ Adresse IP:Port du proxy : " + $IPProxy + ":3128")
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName "ProxyServer" -Type String -value ($IPProxy + ":3128")
	}
	if ( $IPPronote -ne "" ){
		Audit "         @ Exception du proxy : 10.*;<local>;$IPPronote"
		if ( $Show -ne $True ) {
			$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName "ProxyOverride" -Type String -value "10.*;<local>;$IPPronote"
		}
	}else{
		Audit "         @ Exception du proxy : 10.*;<local>"
		if ( $Show -ne $True ) {
			$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName "ProxyOverride" -Type String -value "10.*;<local>"
		}
	}
	Audit "         @ Page d'accueil du collège : $URLEtab"
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Microsoft\Internet Explorer\Main" -ValueName "Start Page" -Type String -value $URLEtab
	}

	# - Composants Windows, Internet Explorer
	Audit "      - Modèles > Composants Windows > Internet Explorer"
	Audit "         @ Désactiver la modification de la page d'accueil : activée"
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Microsoft\Internet Explorer\Main" -ValueName "Start Page" -Type String -value $URLEtab
	}

	# - Firefox ESR
	Audit "      - Modèles > Mozilla > Firefox"
	Audit "         @ Page d'accueil du collège : $URLEtab"
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Mozilla\Firefox\Homepage" -ValueName "Locked" -Type DWord -value 1
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Mozilla\Firefox\Homepage" -ValueName "StartPage" -Type String -value "homepage"
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Mozilla\Firefox\Homepage" -ValueName "URL" -Type String -value $URLEtab
	}
	Audit "         @ Paramètres du proxy"
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Mozilla\Firefox\Proxy" -ValueName "Mode" -Type String -value "system"
	}
	if ( $IPPronote -ne "" ){
		if ( $Show -ne $True ) {
			$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Mozilla\Firefox\Proxy" -ValueName "Passthrough" -Type String -value "10.0.0.0/8, $IPPronote"
		}
	}else{
		if ( $Show -ne $True ) {
			$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Mozilla\Firefox\Proxy" -ValueName "Passthrough" -Type String -value "10.0.0.0/8"
		}
	}

	# - Google Chrome
	Audit "      - Modèles > Google"
	Audit ("         @ Adresse IP:Port du proxy : " + $IPProxy + ":3128")
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Google\Chrome" -ValueName "ProxyServer" -Type String -value ($IPProxy + ":3128")
	}
	Audit "         @ Page d'accueil du collège : $URLEtab"
	if ( $Show -ne $True ) {
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Google\Chrome" -ValueName "HomepageLocation" -Type String -value $URLEtab
		$tmp = Set-GPRegistryValue -Name "$UserDestGPOName" -key "HKCU\Software\Policies\Google\Chrome\RestoreOnStartupURLs" -ValueName "1" -Type String -value $URLEtab
	}

	# - Pronote dans la Default Domain Policy
	Audit "      - Modèles > Magret > 09. Modules pédagogiques MAGRET > 9.1 Fonctionnalités Magret Utilisateurs"
	if ( $IPPronote -ne "" ){
		Audit "         @ Affectation de la route pour l'adresse IP Pronote : $IPPronote,255.255.255.255,$IPRouteur"
		if ( $Show -ne $True ) {
			$tmp = Set-GPRegistryValue -Name "Default Domain Policy" -key "HKCU\Software\Policies\Magret\Routes" -ValueName "Route" -Type String -value "$IPPronote,255.255.255.255,$IPRouteur"
		}
	}
}


# Remplacement des stratégies de référence par les stratégies du collège
if ( $DoMakeCurrentAsRef ) {

	if ( $MakeCurrentAsRefUserWith -eq "" ) {
		$UserSrc4RefGPOName = "Utilisateurs"
	}else{
		$UserSrc4RefGPOName = $MakeCurrentAsRefUserWith
	}
	if ( $MakeCurrentAsRefMachineWith -eq "" ) {
		$MachineSrc4RefGPOName = "Matériel"
	}else{
		$MachineSrc4RefGPOName = $MakeCurrentAsRefMachineWith
	}

	if ( Check-GPO "$UserSrc4RefGPOName" -and Check-GPO "$MachineSrc4RefGPOName" ) {
		$replPathComp = "Last"
		if ( $MakeCurrentAsRefVersion -ne "" ) {
			$replPathComp = $MakeCurrentAsRefVersion
		}
		Audit ">> Remplacement des stratégies de référence [version $replPathComp] par les stratégies en service ..."
		$rep = Read-Host -Prompt "  - Les stratégies de référence actuelle vont être effacées, êtes-vous sûr de vouloir continuer (O/N) "
		if ( $rep -match "^o$" ) {
			$TimeStamp = ( Get-Date -format "yyyyMMddHHmmss" )
			$BackupPath = $rootPath + "\Backups\_tmp"

			# Create temp folder
			Audit "  - Création des répertoires temporaires ..."
			if ( $Show -ne $True ) {
				$tmp = New-Item -ItemType directory -path "$BackupPath\Utilisateurs" -force
				$tmp = New-Item -ItemType directory -path "$BackupPath\Matériel" -force
			}

			# Utilisateurs
			Audit "  - Sauvegarde des stratégies utilisateurs '$UserSrc4RefGPOName' ..."
			if ( $Show -ne $True ) {
				$tmp = Backup-Gpo -Name "$UserSrc4RefGPOName" -Path "$BackupPath\Utilisateurs" -Comment ("Sauvegarde GPO '" + $UserSrc4RefGPOName + "' " + $Domaine + " " + $TimeStamp)
			}

			# Matériel
			Audit "  - Sauvegarde des stratégies ordinateurs '$MachineSrc4RefGPOName' ..."
			if ( $Show -ne $True ) {
				$tmp = Backup-Gpo -Name "$MachineSrc4RefGPOName" -Path "$BackupPath\Matériel" -Comment ("Sauvegarde GPO '" + $MachineSrc4RefGPOName + "' " + $Domaine + " " + $TimeStamp)
			}

			# Delete actual ref
			Audit "  - Suppression des stratégies de référence utilisateur [version $replPathComp] ..."
			if ( $Show -ne $True ) {
				$tmp = Remove-Item -path "$rootPath\Referentiel\$replPathComp\Utilisateurs" -Recurse -Force
			}
			Audit "  - Suppression des stratégies de référence ordinateur [version $replPathComp] ..."
			if ( $Show -ne $True ) {
				$tmp = Remove-Item -path "$rootPath\Referentiel\$replPathComp\Matériel" -Recurse -Force
			}

			# Replace ref
			Audit "  - Déplacement des stratégies utilisateurs '$UserSrc4RefGPOName' dans le référentiel [version $replPathComp] ..."
			if ( $Show -ne $True ) {
				$tmp = Move-Item -Path "$BackupPath\Utilisateurs" -Destination "$rootPath\Referentiel\$replPathComp\Utilisateurs"
			}
			Audit "  - Déplacement des stratégies ordinateurs '$MachineSrc4RefGPOName' dans le référentiel [version $replPathComp] ..."
			if ( $Show -ne $True ) {
				$tmp = Move-Item -Path "$BackupPath\Matériel" -Destination "$rootPath\Referentiel\$replPathComp\Matériel"
			}

			# Change GPO name in manifest.xml
			Audit "  - Modification du nom des objets dans les manifest.xml ..."
			if ( $Show -ne $True ) {
				$tmp = New-Item -ItemType directory -path "$BackupPath\Utilisateurs" -force
				$tmp = New-Item -ItemType directory -path "$BackupPath\Matériel" -force
				# Patch GPO name
				$filePathToTask = "$rootPath\Referentiel\$replPathComp\Utilisateurs\manifest.xml"
				[xml]$xml = Get-Content "$filePathToTask"
				$xml.PreserveWhitespace = $True
				$xml.Backups.BackupInst.GPODisplayName.'#cdata-section' = "Utilisateurs"
				$xml.Save("$BackupPath\Utilisateurs\manifest.xml")
				$tmp = Move-Item -Path "$BackupPath\Utilisateurs\manifest.xml" -Destination "$rootPath\Referentiel\$replPathComp\Utilisateurs\manifest.xml" -Force
				# Patch GPO name
				$filePathToTask = "$rootPath\Referentiel\$replPathComp\Matériel\manifest.xml"
				[xml]$xml = Get-Content "$filePathToTask"
				$xml.PreserveWhitespace = $True
				$xml.Backups.BackupInst.GPODisplayName.'#cdata-section' = "Matériel"
				$xml.Save("$BackupPath\Matériel\manifest.xml")
				$tmp = Move-Item -Path "$BackupPath\Matériel\manifest.xml" -Destination "$rootPath\Referentiel\$replPathComp\Matériel\manifest.xml" -Force
			}

			# Clean temp folder
			Audit "  - Suppression des répertoires temporaires ..."
			if ( $Show -ne $True ) {
				$tmp = Remove-Item -path "$BackupPath" -Recurse -Force
			}
		}else{
			Audit "  - Opération annulée par l'utilisateur." "LOG"
		}
	}else{
		if ( Check-GPO "$UserSrc4RefGPOName" ) {
			Audit "  L'objet GPO matériel '$MachineSrc4RefGPOName' n'existe pas !" "WARNING"
		}else{
			Audit "  L'objet GPO utilisateurs '$UserSrc4RefGPOName' n'existe pas !" "WARNING"
		}
	}
}

Write-Output ""
Audit "Traitement terminé !"
Audit "------------------------------------------------------------------------`r`n"