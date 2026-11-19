function [idx,mask] = ufln_visible_landmarks(state,L,map,cfg,visited)
p=state(1:2); th=state(3); n=size(L,1); mask=false(n,1);
half=deg2rad(cfg.sensor.fov_full_deg)/2;
for i=1:n
    if nargin>=5 && numel(visited)>=i && visited(i), continue; end
    v=L(i,:)-p; d=norm(v);
    if d<1e-9 || d>cfg.sensor.range, continue; end
    err=abs(ufln_wrap(atan2(v(2),v(1))-th));
    if err>half, continue; end
    if ~ufln_line_of_sight(p,L(i,:),map,cfg), continue; end
    mask(i)=true;
end
idx=find(mask);
end
