----------------------------------------------------------------------------------------------------------------
>> Synchroniser ECOCD31 RGPO depuis Github
----------------------------------------------------------------------------------------------------------------

Sur le serveur01.


1 - Installation du Kit ECOCD31 RGPO
------------------------------------

Executer le script Install_Kit_ECOCD31_RGPO.cmd


(((((((((((((((((((((((((((((((((
Pour plus de détails sur ce que ce script fait,
ci-dessous, le déroulé de l'installation manuelle :

- Installer Notepad++ avec npp.7.8.4.Installer.x64.exe
	- options par défaut
- Installer Git avec Git-2.25.0-64-bit.exe
	- Don't create a Start Menu Folder
	- Use Notepad++ as Git's default editor
	- Git from the command line and also from 3rd-party software
	- Use the native Windows Secure Channel library
	- Checkout as-is, commit as-is
	- Use Windows' default console window
	- ... Install !

Dans le profil de l'Administrateur du domaine, copier le dossier .ssh

Ouvrir Git Bash dans le dossier D:\Sources SRV01 avec le menu contextuel.
saisir la commande :
git clone ssh://git@rgpo/manoletto/ECOCD31-Restore-GPO.git ECOCD31-Restore-GPO
...

Dépôt en place ! 
)))))))))))))))))))))))))))))



2 - Mise-à-jour de ECOCD31 RGPO
-------------------------------

Dans le dossier D:\Sources SRV01\ECOCD31-Restore-GPO
lancer Git Bash, puis éxécuter la commande :
git pull

