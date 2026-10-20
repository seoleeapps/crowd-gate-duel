#!/usr/bin/env python3
"""실제 viewport 캡처를 등록 자산 manifest로 조립한다. 실행 뒤 registration-assets 검증을 한다."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,shutil
root=Path('.')
assets=root/'play-store/assets';assets.mkdir(exist_ok=True)
if not (assets/'icon-master.png').is_file():
 raise SystemExit('Rasterize game/assets/art/icon.svg to play-store/assets/icon-master.png first')
shot=Image.open(root/'build/listing/en/normal-bot-and-restore--normal-gate-3.png').convert('RGB')
frame=Image.new('RGB',(1024,500),'#f4d7b4')
draw=ImageDraw.Draw(frame)
fontfile=root/'game/assets/fonts/Fredoka-Variable.ttf'
font=ImageFont.truetype(str(fontfile),70)
large=ImageFont.truetype(str(fontfile),104)
draw.text((58,126),'Crowd Gate',font=font,fill='#2d2621')
draw.text((58,204),'Duel',font=large,fill='#ab4a07')
small=shot.resize((252,448),Image.Resampling.LANCZOS)
frame.paste(small,(738,26))
frame.save(assets/'feature-master.png')
items=[{'id':'icon','kind':'icon','path':'assets/icon-512.png','width':512,'height':512,'source':'play-store/assets/icon-master.png','fit':'contain'}, {'id':'feature','kind':'feature','path':'assets/feature-graphic-1024x500.png','width':1024,'height':500,'source':'play-store/assets/feature-master.png'}]
files=[('01-tutorial','mandatory-tutorial--quiz-preview-4.png'),('02-duel','normal-bot-and-restore--normal-gate-3.png'),('03-result','normal-bot-and-restore--05-normal-result.png')]
for lang in ['en','ko']:
 for name,file in files:
  path=f'screenshots/phone/{name}.png' if lang=='en' else f'screenshots/phone-ko/{name}.png'
  items.append({'id':f'{lang}-{name}','kind':'screenshot','path':path,'width':1080,'height':1920,'source':f'build/listing/{lang}/{file}'})
for kind in ['tablet-7','tablet-10']:
 for i,file in enumerate(['normal-bot-and-restore--04-home.png','normal-bot-and-restore--normal-gate-3.png','normal-bot-and-restore--05-normal-result.png','cosmetics-settings-and-replay--06-cosmetics.png'],1):
  items.append({'id':f'{kind}-{i}','kind':'screenshot','path':f'screenshots/{kind}/{i:02}.png','width':1440,'height':2560,'source':f'build/listing/tablet/{file}'})
manifest={'out_dir':'play-store','background':'#fbf7f0','brand':'Crowd Gate Duel existing native art and real rendered runtime screenshots. No generated gameplay.', 'items':items,'rules':[{'kind':'screenshot','min':3}]}
(root/'play-store/assets-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
p=root/'play-store/google-play.config.json';cfg=json.loads(p.read_text());cfg['assets']['sevenInchTabletScreenshots']=[f'play-store/screenshots/tablet-7/{i:02}.png' for i in range(1,5)];cfg['assets']['tenInchTabletScreenshots']=[f'play-store/screenshots/tablet-10/{i:02}.png' for i in range(1,5)];p.write_text(json.dumps(cfg,ensure_ascii=False,indent=2)+'\n')
