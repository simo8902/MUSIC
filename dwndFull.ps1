# prodbysimo 112325
# Download full as m4a 

param([string]$url)

$channel = ($url -split 'youtube\.com/@')[1] -replace '/videos',''
New-Item -ItemType Directory -Force $channel | Out-Null
Set-Location $channel

yt-dlp --cookies "$PSScriptRoot/cookies.txt" `
       --extractor-args "youtube:player_client=default" `
       --flat-playlist --get-id "$url" |
    Select-Object -Unique |
    ForEach-Object {
        yt-dlp -f 140 --ignore-errors --quiet --no-warnings `
               --download-archive dwndlist.txt `
               "https://www.youtube.com/watch?v=$_" 
    }
