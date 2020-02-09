<img src="https://github.com/manoletto/ECOCD31/blob/master/img/cd31.png" alt="CD31" style="float: left; padding-right: 20px;">&nbsp;&nbsp;&nbsp;&nbsp;<img src="https://github.com/manoletto/ECOCD31/blob/master/img/econocom.png" alt="Econocom" style="float: left;"><br style="clear: both;">

**ECOCD31-Restore-GPO**
------------------------------------------------------------------------------------------------------

*Outil de déploiement des stratégies de groupe CD31.*

Accompagné des fichiers modèles de stratégies et des stratégies de groupe
de référence, le script **Restore-GPO.ps1** met-à-jour les modèles de stratégies,
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

	Restore-GPO.ps1 -DomainEtab COL-031XXXXX01 -URLEtab https://.../ -IPProxy A.B.C.D -DisableMakeCurrentAsRef
le déploiement peut être automatisé.

Pour plus d'informations, exécuter :

	Get-Help Restore-GPO.ps1 -full

Le dossier '**Backup**' contient les sauvegardes horodatées, le dossier
'**Referentiel**' contient les stratégies de référence.
Le dossier '**PolicyDefinitions**' contient les modèles de stratégies.


**Paramètres**
------------------------------------------------------------------------------------------------------

**-DomainEtab**<br><br>
Le domaine du collège sans le .local.

	-DomainEtab COL-031XXXXX01

**-URLEtab**<br><br>
L'adresse du site web du collège.

	-URLEtab https://.../

**-IPProxy**<br><br>
L'adresse IPv4 du Proxy Web.

	-IPProxy A.B.C.D

**-BackupOnlyUser**<br><br>
Switch pour ne sauvegarder que les stratégies utilisateur du collège.<br>
Inactif si **-DisableBackupCurrentGPO** est utilisé.

**-BackupOnlyMachine**<br><br>
Switch pour ne sauvegarder que les stratégies machine du collège.<br>
Inactif si **-DisableBackupCurrentGPO** est utilisé.

**-DisableDeploySchema**<br><br>
Switch pour désactiver la mise-à-jour des fichiers modèles de stratégies.

**-DisableBackupCurrentGPO**<br><br>
Switch pour désactiver la sauvegarde des stratégies du collège.

**-DisableRestoreRefGPO**<br><br>
Switch pour désactiver la restauration des stratégies de référence.

**-DisablePatchValues**<br><br>
Switch pour désactiver le questionnaire et la modification des valeurs propres au collège.

**-DisableMakeCurrentAsRef**<br><br>
Switch pour désactiver le remplacement des stratégies de référence par les stratégies du collège.

**-MakeCurrentAsRef**<br><br>
Switch qui désactive tous les traitements sauf le remplacement
des stratégies de référence par les stratégies du collège.<br>
Equivalent à utiliser tous les paramètres
de désactivation **-Disable...** sauf **-DisableMakeCurrentAsRef**.


**Notes**
------------------------------------------------------------------------------------------------------

Avec l'idée de faciliter le déploiement des stratégies de groupe, tout en apportant
un mécanisme simple de sauvegarde, ce projet est ouvert et toutes suggestions est la bienvenue.