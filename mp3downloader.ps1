# prodbysimo 0109226
# ENSURE THESE ARE INSTALLED:
## yt-dlp, ffmpeg, node.js, typescript, bgutil

param([string]$url)

function BgutilAlive {
    $port = $env:BGUTIL_PORT
    if (-not $port) { return $false }
    try {
        Invoke-WebRequest "http://127.0.0.1:$port/ping" -TimeoutSec 2 -UseBasicParsing | Out-Null
        return $true
    } catch {
        return $false
    }
}

if (-not $url) { Write-Error "URL missing"; exit 1 }

if ($url -match 'youtube\.com/@([^/]+)') {
    $channel = $matches[1]
    New-Item -ItemType Directory -Force $channel | Out-Null
	
    $ids = yt-dlp `
        --extractor-args "youtube:player_client=mweb" `
        --flat-playlist `
        --skip-download `
        --print id `
        "$url" 2>$null
}
elseif ($url -match 'youtube\.com/watch\?v=([^&]+)') {
    $ids = @($matches[1])
}
else {
    Write-Error "Invalid URL"
    exit 1
}

$index = 1
$total = $ids.Count
$fail = @()

foreach ($id in $ids) {
    Write-Host "Processing $index / $total"

    $out = yt-dlp `
        --quiet `
        --extractor-args "youtube:player_client=mweb" `
        --extract-audio --audio-format mp3 --audio-quality 0 `
        --download-archive dwndlist.txt `
        -o "$channel\%(title)s.%(ext)s" `
        "https://www.youtube.com/watch?v=$id" 2>&1

    if ($out -match "ExtractAudio|Deleting original file") {
        Write-Host "OK $id"
        $index++
        continue
    }

    if (-not (BgutilAlive)) {
        Write-Error "bgutil server NOT running"
        exit 1
    }

    $out2 = yt-dlp `
        --quiet `
        --extractor-args "youtube:player_client=android;youtube:po_token=bgutil" `
        --extract-audio --audio-format mp3 --audio-quality 0 `
        --download-archive dwndlist.txt `
        -o "$channel\%(title)s.%(ext)s" `
        "https://www.youtube.com/watch?v=$id" 2>&1

    if ($out2 -match "ERROR:") {
		Write-Host "FAILED $id"
		$fail += $id
	} else {
		# Write-Host "OK (bgutil) $id"
	}

    $index++
}

Write-Host "Done."
if ($fail.Count -gt 0) {
    Write-Host "Failed total: $($fail.Count)"
    $fail
}
