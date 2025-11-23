import requests

token = 'UR TOKEN'
file = {'file': open('unknown.m4a', 'rb')}

resp = requests.post(
    'https://enterprise.audd.io/',
    data={'api_token': token, 'every': 5, 'return': 'spotify,apple_music'},
    files=file
)
print(resp.json())