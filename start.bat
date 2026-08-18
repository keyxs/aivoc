@echo off
chcp 65001 >nul
cd /d "%~dp0"

REM ========== 端口配置：参数化，默认 12580 ==========
set PORT=%1
if "%PORT%"=="" set PORT=12580

echo ========================================
echo   智能文本润色系统 - 启动中...
echo ========================================
echo.

REM ========== 检查 Python 安装 ==========
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到 Python，请先安装 Python 3.x
    echo 下载地址: https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)
echo [1/4] Python 环境检测通过

REM ========== 检测端口占用 ==========
netstat -ano | findstr ":%PORT% " | findstr LISTENING >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo [错误] 端口 %PORT% 已被占用！
    echo 请选择：
    echo   A. 关闭占用 %PORT% 的程序后重试
    echo   B. 使用自定义端口：start.bat 8080
    echo.
    pause
    exit /b 2
)
echo [2/4] 端口 %PORT% 可用

REM ========== 提示访问地址 ==========
echo.
echo [3/4] 正在启动本地 HTTP 服务器...
echo       访问地址: http://localhost:%PORT%
echo.

REM ========== 延迟 2 秒后自动打开浏览器 ==========
start /b cmd /c "timeout /t 2 >nul & start http://localhost:%PORT%"

echo ========================================
echo   系统已启动，请勿关闭此窗口。
echo   关闭此窗口将停止服务。
echo   (端口: %PORT%)
echo ========================================
echo.

REM ========== 启动 HTTP 服务器 ==========
python -m http.server %PORT%
