@echo off
setlocal

echo ========================================================
echo   HOSTELIX PRO - Docker Environment Launcher
echo ========================================================
echo.

REM Check if Docker is installed
where docker >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker is not installed or not in PATH.
    echo Please install Docker Desktop first: https://www.docker.com/products/docker-desktop/
    pause
    exit /b 1
)

echo [INFO] Checking Docker status...
docker info >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker daemon is not running.
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

cd backend

echo.
echo [INFO] Building and starting containers...
echo This may take a while the first time (downloading images).
echo.

docker-compose up --build -d

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to start Docker containers.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Backend, Database, and Redis are running!
echo.
echo   API URL:       http://localhost:3000
echo   Database:      PostgreSQL (port 5432)
echo   Redis:         Port 6379
echo.
echo [INFO] Following logs (Press Ctrl+C to stop following logs, containers will keep running)...
echo.

docker-compose logs -f backend

endlocal
