"""Original deterministic music/SFX synthesis; no third-party recordings."""
from pathlib import Path
import math, random, wave, struct

RATE = 24000
OUT = Path('game/assets/audio')
OUT.mkdir(parents=True, exist_ok=True)
random.seed(719)

def save(name, samples):
    peak = max(1.0, max(abs(x) for x in samples))
    pcm = b''.join(struct.pack('<h', int(max(-1,min(1,x/peak))*28000)) for x in samples)
    with wave.open(str(OUT/(name+'.wav')), 'wb') as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(RATE); out.writeframes(pcm)

def tone(freq, t, decay=8):
    return math.sin(math.tau*freq*t)*math.exp(-decay*t)

for name, freq, duration in [('tap',800,.09),('drop',440,.25),('wood',160,.19),('metal',540,.32),('coin',1200,.25),('rescue',600,.6),('lose',240,.85),('win',660,.9),('perfect',880,.65)]:
    samples=[]
    for i in range(int(RATE*duration)):
        t=i/RATE
        attack=min(1,t/.006)
        release=min(1,(duration-t)/.02)
        if name in ('wood','metal'):
            value=tone(freq,t,18)*.55+tone(freq*2.71,t,25)*.2+(random.random()*2-1)*math.exp(-55*t)*.25
        elif name in ('win','perfect','coin'):
            value=sum(tone(freq*ratio,max(0,t-offset),6)*.24 if t>=offset else 0 for ratio,offset in [(1,0),(1.25,.06),(1.5,.12),(2,.18)])
        else:
            sweep=(-240 if name=='lose' else -160 if name=='drop' else 230 if name=='rescue' else 0)
            value=math.sin(math.tau*(freq*t+sweep*t*t/2))*math.exp(-5*t)*.5
        samples.append(value*attack*release)
    save(name,samples)

# 16-bar, 96 BPM marimba/pluck loop: Cmaj7 - Am7 - Fmaj7 - G6.
beat=.625
duration=64*beat
samples=[0.0]*int(duration*RATE)
progression=[(48,52,55,59),(45,48,52,55),(41,45,48,52),(43,47,50,52)]
def note(midi,start,length,amp,bass=False):
    freq=440*2**((midi-69)/12)
    begin=int(start*RATE)
    for j in range(int(length*RATE)):
        if begin+j>=len(samples): break
        t=j/RATE
        env=min(1,t/.008)*min(1,(length-t)/.04)*math.exp(-(3 if bass else 5)*t)
        value=(math.sin(math.tau*freq*t)+.18*math.sin(math.tau*freq*2*t))
        samples[begin+j]+=value*env*amp
for bar in range(16):
    chord=progression[(bar//2)%4]
    for step in range(8):
        note(chord[[0,2,1,3,2,1,3,2][step]]+24,(bar*4+step*.5)*beat,.8,.12)
    for step in (0,2): note(chord[0],(bar*4+step)*beat,1.1,.18,True)
    for step in range(4):
        start=int((bar*4+step)*beat*RATE)
        for j in range(int(.08*RATE)):
            samples[start+j]+=(random.random()*2-1)*math.exp(-j/RATE*90)*.025
# Avoid a seam click while the scene loops the stream.
for i in range(500):
    samples[i]*=i/500
    samples[-1-i]*=i/500
save('skyline',samples)
print('Generated 10 original audio files')
