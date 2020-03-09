<img src="https://github.com/manoletto/ECOCD31/blob/master/img/cd31.png" alt="CD31" style="float: left; padding-right: 20px;">&nbsp;&nbsp;&nbsp;&nbsp;<img src="https://github.com/manoletto/ECOCD31/blob/master/img/econocom.png" alt="Econocom" style="float: left;"><br style="clear: both;">

**ECOCD31-Restore-GPO**
------------------------------------------------------------------------------------------------------

*Outil de déploiement des stratégies de groupe 'Matériel' et 'Utilisateurs' CD31.*

Accompagné des fichiers modèles de stratégies et des stratégies de groupe
de référence 'Matériel' et 'Utilisateurs', le script **Restore-GPO.ps1**
met-à-jour les modèles de stratégies, sauvegarde les stratégies 'Matériel' et
'Utilisateurs' du collège et les remplace par les stratégies de référence. Il permet
aussi de modifier les valeurs propres au collège.
Enfin, il permet de remplacer les stratégies de référence 'Matériel' et 'Utilisateurs'
par les stratégies 'Matériel' et 'Utilisateurs' du collège, permettant ainsi de les restaurer rapidement.

Différentes versions des stratégies de référence peuvent être utilisées. Lors de l'activation
des stratégies de référence et du remplacement des stratégies de référence par celles du collège,
la "dernière" version est utilisée par défaut. Sauf à utiliser respectivement les paramètres
**-RestoreRefGPOVersion** et **-MakeCurrentAsRefVersion**.
Chaque version est stockée dans un sous-dossier du dossier '**Referentiel**'.
Les noms de version '**v1**' et '**Last**' sont réservés.

Si des modifications sont effectuées dans l'établissement, elles peuvent
être sauvegardées et/ou devenir les stratégies de référence en utilisant
le paramètre **-MakeCurrentAsRef**.

Par défaut, ces étapes, sauf le remplacement des stratégies de référence,
sont, dans l'ordre indiqué ci-dessus, toutes exécutées.
Avec les paramètres de commande, chacune d'elles peut être désactivée.

En utilisant la combinaison suivante :

	Restore-GPO.ps1 -URLEtab https://.../
le déploiement peut être automatisé.

Pour plus d'informations, dans le dossier **ECOCD31-Restore-GPO** exécuter :

	Get-Help .\Restore-GPO.ps1 -full

Le dossier '**Backup**' contient les sauvegardes horodatées, le dossier
'**Referentiel**' contient les stratégies de référence.
Le dossier '**PolicyDefinitions**' contient les modèles de stratégies.
Le dossier '**Logs**' contient les journaux des traitements.

<br>

**Paramètres**
------------------------------------------------------------------------------------------------------

<br>

**-URLEtab**<br><br>
L'adresse du site web du collège.

	-URLEtab https://.../

<br>

**-RestoreRefGPOVersion**<br><br>
Lors de l'activation des stratégies de référence, ce paramètre permet d'indiquer la version à utiliser.<br>
Par défaut, la dernière version est utilisée.
Inactif si **-DisableRestoreRefGPO** est utilisé.

<br>

**-BackupOnlyUser**<br><br>
Switch pour ne sauvegarder que les stratégies utilisateur du collège.<br>
Inactif si **-DisableBackupCurrentGPO** est utilisé.

<br>

**-BackupOnlyMachine**<br><br>
Switch pour ne sauvegarder que les stratégies machine du collège.<br>
Inactif si **-DisableBackupCurrentGPO** est utilisé.

<br>

**-DisableDeploySchema**<br><br>
Switch pour désactiver la mise-à-jour des fichiers modèles de stratégies.

<br>

**-DisableBackupCurrentGPO**<br><br>
Switch pour désactiver la sauvegarde des stratégies du collège.

<br>

**-DisableRestoreRefGPO**<br><br>
Switch pour désactiver l'activation des stratégies de référence.

<br>

**-DisablePatchValues**<br><br>
Switch pour désactiver le questionnaire et la modification
des valeurs propres au collège.

<br>

**-MakeCurrentAsRef**<br><br>
Switch qui désactive tous les traitements et effectue le remplacement
des stratégies de référence par les stratégies du collège.

<br>

**-MakeCurrentAsRefVersion**<br><br>
Lors du remplacement des stratégies de référence par celles du collège, ce paramètre permet d'indiquer la version à remplacer.<br>
Par défaut, la dernière version est remplacée.
Inactif si **-MakeCurrentAsRef** n'est pas utilisé.

<br>

**Notes**
------------------------------------------------------------------------------------------------------

Pour connaître les évolutions, lire le fichier [Doc/version.txt](./Doc/version.txt)

Avec l'idée de faciliter le déploiement des stratégies de groupe, tout en apportant
un mécanisme simple de sauvegarde, ce projet est ouvert et toute suggestion est la bienvenue.