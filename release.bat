@echo off
echo ======================================================
echo   Deploying msaratwasel-services to PRODUCTION...
echo ======================================================
git push origin main:production
echo.
echo [OK] Pushed to production branch!
echo GitHub Actions is now building and deploying directly to Google Play Production.
