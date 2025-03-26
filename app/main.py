from fastapi import FastAPI, UploadFile, File, Query, HTTPException
from transformers import WhisperProcessor, WhisperForConditionalGeneration
import torch
import requests
import tempfile
import os
import librosa
import torchaudio

app = FastAPI()

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
processor = WhisperProcessor.from_pretrained("openai/whisper-small")
model = WhisperForConditionalGeneration.from_pretrained("openai/whisper-small").to(DEVICE)

def transcribe_audio(file_path: str) -> str:
    waveform, sr = torchaudio.load(file_path, format="mp3")
    resampler = torchaudio.transforms.Resample(orig_freq=sr, new_freq=16000)

    if waveform.shape[0] > 1:
        waveform = torch.mean(waveform, dim=0, keepdim=True)

    audio = resampler(waveform).squeeze()
    
    input_features = processor(audio.cpu().numpy(), sampling_rate=16000, return_tensors="pt").input_features.to(DEVICE)
    predicted_ids = model.generate(input_features)
    return processor.batch_decode(predicted_ids, skip_special_tokens=True)[0]

@app.post("/audio_to_text/")
async def audio_to_text(audio_url: str = Query(None), audio_file: UploadFile = File(None)):
    if not audio_url and not audio_file:
        raise HTTPException(status_code=400, detail="Укажите либо ссылку на аудио, либо загрузите файл.")

    try:
        if audio_url:
            response = requests.get(audio_url)
            if response.status_code != 200:
                raise HTTPException(status_code=400, detail="Ошибка загрузки аудио по URL.")
            temp = tempfile.NamedTemporaryFile(delete=False, suffix=".mp3")
            temp.write(response.content)
            temp.close()
            file_path = temp.name
        else:
            temp = tempfile.NamedTemporaryFile(delete=False, suffix=".mp3")
            temp.write(await audio_file.read())
            temp.close()
            file_path = temp.name
            
        text = transcribe_audio(file_path)
        os.remove(file_path)
        return {"text": text}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
