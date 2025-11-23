import requests, os

token = 'UR TOKEN HERE'
file_path = 'Untitled.mp3'
file = {'file': open(file_path, 'rb')}
resp = requests.post(
    'https://api.audd.io/',
    data={'api_token': token, 'return': 'spotify,apple_music,youtube'},
    files=file
).json()

res = resp.get('result')
s = None
if isinstance(res, list) and res and 'songs' in res[0] and res[0]['songs']:
    s = res[0]['songs'][0]
elif isinstance(res, dict) and res.get('artist'):
    s = res

name = os.path.basename(file_path)
if s:
    artist = s.get('artist', 'unknown')
    title = s.get('title', name)
    spotify = s.get('song_link', s.get('spotify', {}).get('external_urls', {}).get('spotify', ''))
    apple = s.get('apple_music', {}).get('url', '')
    youtube = s.get('youtube', {}).get('url', '')
else:
    artist, title, spotify, apple, youtube  = 'unknown', name, '', ''

print(name)
print(f"{artist} - {title}")
if spotify: print(f"spotify - {spotify}")
if apple: print(f"apple - {apple}")
if youtube: print(f"youtube - {youtube}")