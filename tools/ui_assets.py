"""Original vector illustrations, kept reproducible and crisp at any resolution."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'game/assets'
OUT=ROOT/'illustrations'; OUT.mkdir(parents=True,exist_ok=True)
def svg(body,w=256,h=256):
 return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>'
def save(key,body,w=256,h=256): (OUT/f'{key}.svg').write_text(svg(body,w,h),encoding='utf-8')
def box(x,y,scale=1,color='#e9a451'):
 return f'<g transform="translate({x} {y}) scale({scale})" stroke="#684632" stroke-width="5" stroke-linejoin="round"><path fill="{color}" d="M0 0 65-30 130 0 65 32Z"/><path fill="#ba733f" d="M0 0 65 32 65 104 0 72Z"/><path fill="#f7bd65" d="M65 32 130 0 130 72 65 104Z"/><path d="M10 17 55 40M10 58 55 81M76 41 119 20M76 81 119 60" fill="none" stroke="#ffe0a0" stroke-width="9"/></g>'
base='<circle cx="128" cy="128" r="120" fill="#16364f"/><ellipse cx="128" cy="221" rx="92" ry="16" fill="#10253c"/>'
save('stabilizer',base+box(62,135,1)+ '<path d="M77 42V81Q77 127 128 127Q179 127 179 81V42" fill="none" stroke="#14293e" stroke-width="44"/><path d="M77 42V81Q77 127 128 127Q179 127 179 81V42" fill="none" stroke="#f46b88" stroke-width="31"/><path d="M77 40V65M179 40V65" stroke="#c0eeff" stroke-width="31"/><path d="M46 104 29 128M207 103 223 126M128 145V162" stroke="#ffe177" stroke-width="7" stroke-linecap="round"/>')
save('safety',base+box(62,124,1)+'<path d="M128 35 198 61V109Q197 161 128 198Q59 161 58 109V61Z" fill="#4bd9d1" fill-opacity=".9" stroke="#12667b" stroke-width="8"/><path d="m95 106 24 24 47-56" fill="none" stroke="#f6ffea" stroke-width="14" stroke-linecap="round" stroke-linejoin="round"/>')
save('undo',base+box(85,128,.83)+'<path d="M42 219V42H189V96" fill="none" stroke="#ffce65" stroke-width="16" stroke-linejoin="round"/><path d="M183 95V114Q183 137 164 130" fill="none" stroke="#b9e9ff" stroke-width="9"/><path d="M152 78Q109 54 86 98M80 73 82 108 118 102" fill="none" stroke="#b9a4ff" stroke-width="11" stroke-linejoin="round"/>')
for key,colors in {'day':('#438ddd','#b1efff','#f8e5a4'),'sunset':('#624588','#fa9d89','#ffe594'),'night':('#131b48','#256b8f','#71f4d2')}.items():
 top,horizon,light=colors
 save(key,f'<defs><linearGradient id="sky" x2="0" y2="1"><stop stop-color="{top}"/><stop offset="1" stop-color="{horizon}"/></linearGradient></defs><rect width="600" height="180" rx="20" fill="url(#sky)"/><circle cx="475" cy="48" r="28" fill="{light}"/><path d="M0 137 75 76 142 143 231 87 322 141 395 97 510 149 600 103V180H0Z" fill="#17334e" opacity=".5"/><path d="M40 43H132M26 54H96M363 85H421" stroke="{light}" stroke-width="12" opacity=".55" stroke-linecap="round"/>'+box(246,99,.6),600,180)
trophy='<path d="M79 47H177V101Q177 146 128 159Q79 146 79 101Z" fill="#ffcd54" stroke="#c58531" stroke-width="7"/><path d="M77 60H47V89Q47 127 91 123M179 60H209V89Q209 127 165 123" fill="none" stroke="#ffdd75" stroke-width="13"/><path d="M128 158V199M88 213H168" stroke="#ffcc55" stroke-width="19" stroke-linecap="round"/><path d="m128 65 10 22 24 3-18 17 5 24-21-12-22 12 5-24-18-17 24-3Z" fill="#fff2bb"/>'
save('trophy',base+trophy)
def cat(color):
 return f'<path d="M57 116 46 36 104 69Q128 61 154 69L210 36 199 116Q219 199 128 216Q37 199 57 116Z" fill="{color}" stroke="#16344b" stroke-width="8" stroke-linejoin="round"/><path d="m61 59 11 45 24-22M195 59l-11 45-24-22" fill="#ffbbad"/><ellipse cx="95" cy="134" rx="17" ry="23" fill="white"/><ellipse cx="161" cy="134" rx="17" ry="23" fill="white"/><ellipse cx="99" cy="139" rx="8" ry="13" fill="#16344b"/><ellipse cx="157" cy="139" rx="8" ry="13" fill="#16344b"/><path d="m117 162 11 9 11-9" fill="#f6879b"/><path d="M128 171Q116 190 102 176M128 171Q140 190 154 176" fill="none" stroke="#16344b" stroke-width="6" stroke-linecap="round"/>'
for i,color in enumerate(['#ffb74e','#8cdde4','#c0a9f9']): save('avatar'+str(i),base+cat(color))
background='<defs><linearGradient id="bg" x2="0" y2="1"><stop stop-color="#50d5e2"/><stop offset="1" stop-color="#236cc6"/></linearGradient></defs><rect width="512" height="512" rx="96" fill="url(#bg)"/>'
foreground='<ellipse cx="257" cy="410" rx="155" ry="34" fill="#134a89" opacity=".5"/>'+box(143,285,1.75)+box(161,187,1.48,'#bca0ff')+'<g transform="translate(181 51) scale(.63)">'+cat('#ffb74e')+'</g><path d="m104 162 8 21 22 7-22 8-8 22-8-22-22-8 22-7M395 244l6 16 18 6-18 6-6 18-6-18-18-6 18-6" fill="#fff4bb"/>'
(ROOT/'launcher.svg').write_text(svg(background+foreground,512,512))
(ROOT/'launcher_foreground.svg').write_text(svg('<g transform="translate(55 55) scale(.78)">'+foreground+'</g>',512,512))
(ROOT/'launcher_background.svg').write_text(svg(background,512,512))
