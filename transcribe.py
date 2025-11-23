from openai import OpenAI
client = OpenAI(api_key="sk-proj-UR FCKING OPENAI TOKEN KEY")

resp = client.audio.transcriptions.create(
    model="gpt-4o-transcribe",
    file=open("unknown.wav","rb")
)

print(resp.text)
