function c = ufln_point_clearance(p,map,cfg,physicalOnly)
if nargin<4, physicalOnly=false; end
if physicalOnly, infl=0; else, infl=cfg.robot.radius+cfg.safety.margin; end
x=p(1); y=p(2); ws=cfg.workspace;
c=min([x-ws(1)-infl, ws(2)-x-infl, y-ws(3)-infl, ws(4)-y-infl]);
obs=map.obstacles;
for i=1:numel(obs)
    o=obs(i);
    if strcmpi(o.type,'circle')
        d=hypot(x-o.cx,y-o.cy)-(o.r+infl);
    else
        xmin=o.xmin-infl; xmax=o.xmax+infl; ymin=o.ymin-infl; ymax=o.ymax+infl;
        dx=max([xmin-x,0,x-xmax]); dy=max([ymin-y,0,y-ymax]);
        if dx>0 || dy>0
            d=hypot(dx,dy);
        else
            d=-min([x-xmin,xmax-x,y-ymin,ymax-y]);
        end
    end
    c=min(c,d);
end
end
