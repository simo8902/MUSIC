# music-digging scripts

Ensure the following tools are installed and set in system environment path:
```
yt-dlp, ffmpeg, node.js, typescript, bgutil
```

dont worry the script is not that complicated
the script from today update DOESNT use COOKIES, take that in mind but it is still tracable, use vpn if needed
here instructions for every case:
```
git clone https://github.com/Brainicism/bgutil-ytdlp-pot-provider.git
npm install typescript
cd bgutil-ytdlp-pot-provider/server
from server folder:
npx tsc
node build/main.js
run immediately before using my script:
$env:BGUTIL_PORT={YOUR_PORT from the (node build/main.js)}
$env:BGUTIL_PORT={4416} example port
```
P.S. OBV dont close the started server during downloading

# optional venv with python at least 3.10+
```
python -m venv testEnv
.\testEnv\Scripts\activate
optional check venv python version
python --version (to ensure dont mess with the system python version, if diff)
install in the venv the required packages:
pip install yt-dlp, ffmpeg ...
```
small set of scripts for grabbing music without wasting time  
downloads full yt channels, scans huge song databases, pulls lyrics and track info automatically  
searches across all distributors and can even find dead spotify channels with 0 listeners  
works with DistroKid, every other distributor, Apple Music, YouTube Music, and whatever else exists

### uses:
- yt-dlp
- ffmpeg
- openai api
- audd.io
- bgutil

built for God knows who