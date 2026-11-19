function [wp,usedFallback,invalid] = ufln_execute_candidate(state,cand,lm,map,cfg)
p=state(1:2);invalid=false;usedFallback=false;d=cand-p;
if ~all(isfinite(cand)) || norm(d)<1e-10, invalid=true; end
if ~invalid
    if norm(d)>cfg.execution.r_exec,d=d/norm(d)*cfg.execution.r_exec;end
    q=p+d;
    if ufln_segment_safe(p,q,map,cfg),wp=q;return;else,invalid=true;end
end
% shared deterministic fallback around landmark direction
usedFallback=true;base=atan2(lm(2)-p(2),lm(1)-p(1));
for off=cfg.execution.fallback_offsets_deg
    a=base+deg2rad(off);q=p+cfg.execution.r_exec*[cos(a) sin(a)];
    if ufln_segment_safe(p,q,map,cfg),wp=q;return;end
end
wp=p;
end
