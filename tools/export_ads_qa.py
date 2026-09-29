"""Export a separate non-delivery APK using Google demo inventory for native QA."""
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
project=root/'game/project.godot'
config=root/'game/addons/AdmobPlugin/android_export.cfg'
original={p:p.read_bytes() for p in [project,config]}
try:
 project.write_text(original[project].decode('utf-8')+'\n[highstack]\nads/test_mode=true\n',encoding='utf-8')
 config.write_text(original[config].decode('utf-8').replace('ca-app-pub-7928274342057259~5038324740','ca-app-pub-3940256099942544~3347511713'),encoding='utf-8')
 subprocess.run(['godot','--headless','--path',str(root/'game'),'--export-debug','Android',str(root/'build/HighStack3D-AdsQA.apk')],check=True)
finally:
 for path,data in original.items(): path.write_bytes(data)
