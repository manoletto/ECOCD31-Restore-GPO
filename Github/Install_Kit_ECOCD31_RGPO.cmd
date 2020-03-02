@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

ECHO.
ECHO Installation Kit ECOCD31 RGPO v1.* complet
ECHO -----------------------------------------------
ECHO.

ECHO 1 - Installation des outils
ECHO.

REM Nom des programmes d'installation
SET NotepadPPInstall=npp.7.8.4.Installer.x64.exe
SET GitInstall=Git-2.25.0-64-bit.exe

REM Chemin du depot
SET DepotPath="D:\Sources SRV01"

REM Installation Notepad++
IF EXIST Tools\%NotepadPPInstall% (
	IF EXIST "%programfiles%\Notepad++\uninstall.exe" (
		ECHO Desinstallation Notepad++ ...
		START "Desinstallation Notepad++ ..." /WAIT "%programfiles%\Notepad++\uninstall.exe" /S
	)
	IF EXIST "%programfiles(x86)%\Notepad++\uninstall.exe" (
		ECHO Desinstallation Notepad++ x86 ...
		START "Desinstallation Notepad++ ..." /WAIT "%programfiles(x86)%\Notepad++\uninstall.exe" /S
	)
	ECHO Installation Notepad++ ...
	START "Installation Notepad++ ..." /WAIT Tools\%NotepadPPInstall% /S
) ELSE (
	ECHO Le programme Tools\%NotepadPPInstall% est introuvable !
)

REM Installation Git
IF EXIST Tools\%GitInstall% (
	IF EXIST "%programfiles%\Git\unins000.exe" (
		ECHO Desinstallation Git ...
		START "Desinstallation Git ..." /WAIT "%programfiles%\Git\unins000.exe" /VERYSILENT /NORESTART
	)
	ECHO Installation Git, veuillez patienter ...
	START "Installation Git, veuillez patienter ..." /WAIT Tools\%GitInstall% /VERYSILENT /NORESTART /LOADINF="Tools\git.cfg"
) ELSE (
	ECHO Le programme Tools\%GitInstall% est introuvable !
)

ECHO.
ECHO 3 - Mise en place des fichiers pour la connexion SSH
XCOPY .ssh %USERPROFILE%\.ssh\ /E /F /Y
ECHO.

ECHO 6 - Creation du depot dans %DepotPath%
IF NOT EXIST %DepotPath%\ECOCD31-Restore-GPO (
	IF NOT EXIST %DepotPath% MKDIR %DepotPath%
	START "Creation depot" /D %DepotPath% /WAIT "C:\Program Files\Git\cmd\git.exe" clone ssh://git@rgpo/manoletto/ECOCD31-Restore-GPO.git %DepotPath%\ECOCD31-Restore-GPO
	IF NOT EXIST %DepotPath%\ECOCD31-Restore-GPO (
		ECHO Une erreur s'est produite, le depot n'a pas ete cree !
	)
) ELSE (
	ECHO Il existe deja un dossier ECOCD31-Restore-GPO dans le chemin %DepotPath%, depot non cree !
)

ECHO.
ECHO Installation du Kit ECOCD31 RGPO terminee.
ECHO -----------------------------------------------