function [state,found,scanRows,scanAngle] = ufln_scan_for_landmark(state,L,map,cfg,visited)
inc=deg2rad(cfg.sensor.scan_increment_deg);n=ceil(2*pi/inc);scanRows=[];scanAngle=0;found=false;
for k=1:n
    state(3)=ufln_wrap(state(3)+inc);scanAngle=scanAngle+abs(inc);
    [idx,~]=ufln_visible_landmarks(state,L,map,cfg,visited);
    scanRows(end+1,:)=[abs(inc)/cfg.sensor.scan_w,state,0,cfg.sensor.scan_w,ufln_point_clearance(state(1:2),map,cfg,false)]; %#ok<AGROW>
    if ~isempty(idx),found=true;return;end
end
end
