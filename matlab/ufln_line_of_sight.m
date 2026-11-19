function tf = ufln_line_of_sight(a,b,map,cfg)
% Physical landmark line of sight. Robot/safety inflation is intentionally not applied.
tf = ufln_segment_clearance(a,b,map,cfg,true) > 1e-10;
end
