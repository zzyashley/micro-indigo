# PowerShell HTTP server - works on any Windows, no Python needed
# Serves files from the current directory on http://localhost:8080

$root = $PSScriptRoot
if (-not $root) { $root = Split-Path -Parent $MyInvocation.MyCommand.Path }

$mimeMap = @{
    '.html' = 'text/html; charset=utf-8'
    '.js'   = 'application/javascript'
    '.wasm' = 'application/wasm'
    '.tflite' = 'application/octet-stream'
    '.data' = 'application/octet-stream'
    '.binarypb' = 'application/octet-stream'
    '.txt'  = 'text/plain; charset=utf-8'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.json' = 'application/json'
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add('http://localhost:8080/')
try {
    $listener.Start()
} catch {
    Write-Host "[ERROR] Cannot start server on port 8080. Port may be in use."
    Write-Host "Press any key to exit..."
    $null = $Host.UI.Read()
    exit 1
}

Write-Host ""
Write-Host "  ========================================"
Write-Host "     Micro-Indigo Immersive - Local Server"
Write-Host "  ========================================"
Write-Host ""
Write-Host "  URL: http://localhost:8080/"
Write-Host "  Close this window to stop."
Write-Host ""

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $req = $ctx.Request
        $url = $req.RawUrl
        
        # Default to index.html for root path
        if ($url -eq '/' -or $url -eq '') { $url = '/index.html' }
        
        # Remove query string
        $url = $url.Split('?')[0]
        
        # Build local file path
        $relPath = $url.TrimStart('/')
        $localPath = Join-Path $root $relPath
        
        if ([System.IO.File]::Exists($localPath)) {
            $ext = [System.IO.Path]::GetExtension($localPath).ToLower()
            $mime = if ($mimeMap.ContainsKey($ext)) { $mimeMap[$ext] } else { 'application/octet-stream' }
            
            $bytes = [System.IO.File]::ReadAllBytes($localPath)
            $ctx.Response.ContentType = $mime
            $ctx.Response.ContentLength64 = $bytes.Length
            
            # Add CORS headers for wasm loading
            $ctx.Response.Headers.Add('Access-Control-Allow-Origin', '*')
            
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
            $ctx.Response.Close()
            Write-Host "  [OK] $url ($mime)"
        } else {
            $ctx.Response.StatusCode = 404
            $ctx.Response.Close()
            Write-Host "  [404] $url"
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
