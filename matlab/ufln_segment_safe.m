function tf = ufln_segment_safe(a,b,map,cfg)
% Exact continuous segment safety relative to robot radius + safety margin.
tf = ufln_segment_clearance(a,b,map,cfg,false) > 1e-10;
end
