function vrep = ufln_obstacle_repulsion(p,map,cfg,d0,krep)
vrep=[0 0]; obs=map.obstacles; infl=cfg.robot.radius+cfg.safety.margin;
for i=1:numel(obs)
    o=obs(i); dir=[0 0]; d=inf;
    if strcmpi(o.type,'circle')
        q=p-[o.cx o.cy]; nq=norm(q); d=nq-(o.r+infl); if nq>1e-9, dir=q/nq; end
    else
        xmin=o.xmin-infl; xmax=o.xmax+infl; ymin=o.ymin-infl; ymax=o.ymax+infl;
        q=[min(max(p(1),xmin),xmax), min(max(p(2),ymin),ymax)];
        if p(1)>=xmin && p(1)<=xmax && p(2)>=ymin && p(2)<=ymax
            ds=[p(1)-xmin,xmax-p(1),p(2)-ymin,ymax-p(2)]; [~,k]=min(ds);
            dirs=[-1 0;1 0;0 -1;0 1]; dir=dirs(k,:); d=-ds(k);
        else
            vv=p-q; nv=norm(vv); if nv>1e-9, dir=vv/nv; end; d=nv;
        end
    end
    de=max(d,0.05);
    if d<d0
        mag=krep*max(0,(1/de-1/d0))/de^2; vrep=vrep+min(mag,2.5)*dir;
    end
end
if norm(vrep)>3, vrep=vrep/norm(vrep)*3; end
end
