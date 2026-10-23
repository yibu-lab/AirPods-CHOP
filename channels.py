import time, math
FIELDS='ax ay az vertical pitch roll yaw gx gy gz rx ry rz qx qy qz qw source tick'.split()
def onCook(s):
    s.clear(); s.isTimeSlice=False; s.numSamples=1
    b=s.parent(); now=time.monotonic()
    vals={c.name.strip('/'):float(c[0]) for c in s.inputs[0].chans()}
    st=b.fetch('runtime',None)
    if st is None:
        st=dict(tick=None,seen=-1e9,zero=[0,0,0]);b.store('runtime',st)
    tick=vals.get('tick')
    if tick is not None and tick!=st['tick']:
        st['seen']=now;st['tick']=tick
    live=bool(b.par.Active) and now-st['seen']<float(b.par.Timeout)
    angles=[vals.get(k,0)*180/math.pi for k in ('pitch','roll','yaw')]
    if b.par.Recenter and live:
        st['zero']=angles[:];b.par.Recenter=False
    for key in FIELDS:
        value=vals.get(key,1 if key=='qw' else 0)
        if not live and b.par.Zeroonloss:value=1 if key=='qw' else 0
        s.appendChan(key)[0]=value
    for k,a,z in zip(('pitch','roll','yaw'),angles,st['zero']):
        s.appendChan(k+'_deg')[0]=a if live else 0
        s.appendChan(k+'_relative_deg')[0]=((a-z+180)%360-180) if live else 0
        s.appendChan(k+'_control')[0]=((a-z+180)%360-180)*float(b.par.Anglegain) if live else 0
    s.appendChan('accel_magnitude')[0]=math.sqrt(sum(vals.get(k,0)**2 for k in ('ax','ay','az'))) if live else 0
    s.appendChan('vertical_control')[0]=vals.get('vertical',0)*float(b.par.Motiongain) if live else 0
    s.appendChan('live')[0]=int(live)
    s.appendChan('age_seconds')[0]=min(999,max(0,now-st['seen']))
    s.appendChan('extended_data')[0]=int(live and all(k in vals for k in ('gx','rx','qw')))
    b.store('status','LIVE AIRPODS' if live else 'WAITING / STALE')
