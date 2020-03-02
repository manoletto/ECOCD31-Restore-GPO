@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

ECHO.
ECHO Installation Kit ECOCD31 RGPO v1.* pour l'utilisateur en session
ECHO ------------------------------------------------------------
ECHO.

ECHO.
ECHO 2 - Mise en place de la clef
XCOPY .ssh %USERPROFILE%\.ssh\ /E /F /Y
ECHO.

ECHO.
ECHO Installation du Kit ECOCD31 RGPO utilisateur terminee.
ECHO -----------------------------------------------