function c = ufln_segment_clearance(a,b,map,cfg,physicalOnly)
% Minimum continuous clearance along segment a->b.
% physicalOnly=false measures clearance relative to inflated robot+safety bounds.
if nargin<5, physicalOnly=false; end
if physicalOnly, infl=0; else, infl=cfg.robot.radius+cfg.safety.margin; end
ws=cfg.workspace;
% Distance to workspace boundary is linear along the segment; endpoint minima suffice.
ca=min([a(1)-ws(1)-infl,ws(2)-a(1)-infl,a(2)-ws(3)-infl,ws(4)-a(2)-infl]);
cb=min([b(1)-ws(1)-infl,ws(2)-b(1)-infl,b(2)-ws(3)-infl,ws(4)-b(2)-infl]);
c=min(ca,cb);
obs=map.obstacles;
for i=1:numel(obs)
    o=obs(i);
    if strcmpi(o.type,'circle')
        d=ufln_pt_seg_dist([o.cx o.cy],a,b)-(o.r+infl);
    else
        xmin=o.xmin-infl; xmax=o.xmax+infl; ymin=o.ymin-infl; ymax=o.ymax+infl;
        % If segment intersects the inflated rectangle, clearance is non-positive.
        if ufln_segment_intersects_rect(a,b,xmin,xmax,ymin,ymax)
            d=0;
        else
            d=ufln_segment_rect_distance(a,b,xmin,xmax,ymin,ymax);
        end
    end
    c=min(c,d);
end
end
