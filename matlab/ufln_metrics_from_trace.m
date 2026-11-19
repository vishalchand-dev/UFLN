function m=ufln_metrics_from_trace(trace,map,cfg)
M=trace.data;p=M(:,2:3);th=M(:,4);v=M(:,5);w=M(:,6);t=M(:,1);
if size(p,1)<2
    D=0;
else
    D=sum(vecnorm(diff(p),2,2));
end
m.path_length=D;
m.path_ratio=D/max(double(map.reference_length),eps);
% Continuous safety metrics on every executed polyline segment. Rotation-only
% rows have zero-length segments and are still valid clearance observations.
if size(p,1)==1
    segClr=ufln_point_clearance(p(1,:),map,cfg,false);
else
    segClr=zeros(size(p,1)-1,1);
    for k=1:size(p,1)-1
        segClr(k)=ufln_segment_clearance(p(k,:),p(k+1,:),map,cfg,false);
    end
end
valid=segClr(isfinite(segClr));
if isempty(valid)
    m.min_clearance=nan; m.p05_clearance=nan;
else
    m.min_clearance=min(valid); m.p05_clearance=ufln_percentile(valid,5);
end
if D>1e-9
    m.heading_variation_per_m=sum(abs(ufln_wrap(diff(th))))/D;
else
    m.heading_variation_per_m=nan;
end
if numel(t)>2
    dt=max(diff(t),1e-9); av=diff(v)./dt; aw=diff(w)./dt;
    m.linear_accel_rms=sqrt(mean(av.^2));
    m.angular_accel_rms=sqrt(mean(aw.^2));
else
    m.linear_accel_rms=nan; m.angular_accel_rms=nan;
end
if numel(t)>1
    dtv=[diff(t);cfg.controller.dt];
    m.control_effort=sum((v.^2+0.2*w.^2).*dtv);
else
    m.control_effort=0;
end
end
