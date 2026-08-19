# Zero-dependency static HTTP server (replaces python -m http.server)
# Works on any Windows with PowerShell built-in. No Python needed.
param([int]$Port = 12580)
$Root = $PSScriptRoot
if (-not $Root) { $Root = (Get-Location).Path }

try {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$Port/")
    $listener.Start()
} catch {
    Write-Host ""
    Write-Host "[ERROR] Cannot bind http://localhost:$Port/" -ForegroundColor Red
    Write-Host "        It may be in use, or blocked by firewall." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Server running : http://localhost:$Port"
Write-Host "  Root folder    : $Root"
Write-Host "  Press Ctrl+C to stop."
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$mime = @{
    '.html'  = 'text/html; charset=utf-8'
    '.htm'   = 'text/html; charset=utf-8'
    '.js'    = 'application/javascript; charset=utf-8'
    '.mjs'   = 'application/javascript; charset=utf-8'
    '.css'   = 'text/css; charset=utf-8'
    '.json'  = 'application/json; charset=utf-8'
    '.png'   = 'image/png'
    '.jpg'   = 'image/jpeg'
    '.jpeg'  = 'image/jpeg'
    '.gif'   = 'image/gif'
    '.svg'   = 'image/svg+xml'
    '.ico'   = 'image/x-icon'
    '.woff'  = 'font/woff'
    '.woff2' = 'font/woff2'
    '.ttf'   = 'font/ttf'
    '.map'   = 'application/json; charset=utf-8'
    '.txt'   = 'text/plain; charset=utf-8'
    '.md'    = 'text/plain; charset=utf-8'
}

while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
    } catch {
        break
    }

    $req = $ctx.Request
    $res = $ctx.Response

    # Resolve path: empty -> index.html, prevent path traversal
    $rel = $req.Url.AbsolutePath.Trim('/')
    if ($rel -eq '') { $rel = 'index.html' }
    $file = Join-Path $Root ($rel -replace '/', '\')

    $safe = $file.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)
    if ($safe -and (Test-Path $file -PathType Leaf)) {
        try {
            $bytes = [IO.File]::ReadAllBytes($file)
            $ext = [IO.Path]::GetExtension($file).ToLower()
            if ($mime.ContainsKey($ext)) { $res.ContentType = $mime[$ext] }
            else { $res.ContentType = 'application/octet-stream' }
            $res.ContentLength64 = $bytes.LongLength
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
            Write-Host ("200  {0,-30} {1} bytes" -f $rel, $bytes.Length) -ForegroundColor Green
        } catch {
            $res.StatusCode = 500
            Write-Host ("500  {0}" -f $rel) -ForegroundColor Red
        }
    } else {
        $res.StatusCode = 404
        $msg = [Text.Encoding]::UTF8.GetBytes('404 Not Found: ' + $rel)
        $res.ContentType = 'text/plain; charset=utf-8'
        $res.OutputStream.Write($msg, 0, $msg.Length)
        Write-Host ("404  {0}" -f $rel) -ForegroundColor Yellow
    }
    $res.OutputStream.Close()
}
