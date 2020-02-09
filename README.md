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
Avec les paramètres, chacune d'elles peut être désactivée.

Pour plus d'informations, exécuter :
    **Get-Help Restore-GPO.ps1 -full**

Le dossier '**Backup**' contient les sauvegardes horodatées, le dossier
'**Referentiel**' contient les stratégies de référence.
Le dossier '**PolicyDefinitions**' contient les modèles de stratégies.