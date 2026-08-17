@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo   智能文本润色系统 - 启动中...
echo ========================================
echo.

REM 检查 Python 是否安装
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到 Python，请先安装 Python 3.x
    echo 下载地址: https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

echo [1/2] Python 环境检测通过
echo.
echo [2/2] 正在启动本地 HTTP 服务器...
echo       访问地址: http://localhost:12580
echo.

REM 延迟 2 秒后自动打开浏览器
start /b cmd /c "timeout /t 2 >nul & start http://localhost:12580"

echo ========================================
echo   系统已启动，请勿关闭此窗口。
echo   关闭此窗口将停止服务。
echo ========================================
echo.

python -m http.server 12580
