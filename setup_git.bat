@echo off
setlocal

echo ========================================================
echo   HOSTELIX PRO - GitHub Repository Setup
echo ========================================================
echo.

REM Check if git is installed
where git >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Git is not installed.
    echo Please install Git from https://git-scm.com/downloads
    echo.
    echo Once installed, restart your terminal and run this script again.
    pause
    exit /b 1
)

REM Initialize Git
if not exist .git (
    echo [INFO] Initializing Git repository...
    git init
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to initialize git repository.
        pause
        exit /b 1
    )
) else (
    echo [INFO] Git repository already initialized.
)

REM Configure Name/Email if not set (Local only)
git config user.name >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] Configuring local git user...
    set /p GIT_NAME="Enter your Name: "
    set /p GIT_EMAIL="Enter your Email: "
    git config user.name "%GIT_NAME%"
    git config user.email "%GIT_EMAIL%"
)

REM Add files
echo [INFO] Adding files...
git add .
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to add files.
    pause
    exit /b 1
)

REM Commit
echo [INFO] Committing files...
git commit -m "Initial commit of Hostelix Pro"
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] Nothing to commit (clean working tree).
)

echo.
echo ========================================================
echo   Repository Ready!
echo ========================================================
echo.
echo Now you need to push this to GitHub.
echo.
echo OPTION 1: Using GitHub CLI (Recommended)
echo ----------------------------------------
echo 1. Run: gh auth login
echo 2. Run: gh repo create hostelix-pro --public --source=. --remote=origin --push
echo.
echo OPTION 2: Manual (Web Browser)
echo ------------------------------
echo 1. Go to https://github.com/new
echo 2. Create a repository named "hostelix-pro"
echo 3. Run the following commands in this terminal:
echo.
echo    git remote add origin https://github.com/YOUR_USERNAME/hostelix-pro.git
echo    git branch -M main
echo    git push -u origin main
echo.
echo ========================================================
pause
