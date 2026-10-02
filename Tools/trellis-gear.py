import shutil, sys
from gradio_client import Client, handle_file
G=sys.argv[1]
c=Client('trellis-community/TRELLIS',verbose=False)
jobs={'gladius':['gladius.png'],'sheath':['sheath.png'],'shield':['shield_front.png','shield_back.png']}
for name,imgs in jobs.items():
    for attempt in range(2):
        try:
            c.predict(api_name="/start_session")
            multi=[{"image":handle_file(f'{G}/{i}'),"caption":None} for i in imgs] if len(imgs)>1 else []
            r=c.predict(handle_file(f'{G}/{imgs[0]}'),multi,0,7.5,12,3.0,12,'multidiffusion' if multi else 'stochastic',0.9,1024,api_name="/generate_and_extract_glb")
            p=r[2] if isinstance(r[2],str) else r[2].get('value',r[1]); p=p if isinstance(p,str) else r[1]
            shutil.copy(p,f'{G}/{name}.glb'); print(name,'ok',flush=True); break
        except Exception as e: print(name,'fail',attempt,repr(e)[:300],flush=True)
