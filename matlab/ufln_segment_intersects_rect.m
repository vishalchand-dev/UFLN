function tf = ufln_segment_intersects_rect(a,b,xmin,xmax,ymin,ymax)
% Liang-Barsky clipping. Touching counts as intersection.
d=b-a; p=[-d(1), d(1), -d(2), d(2)]; q=[a(1)-xmin, xmax-a(1), a(2)-ymin, ymax-a(2)];
u1=0;u2=1;
for i=1:4
    if abs(p(i))<1e-14
        if q(i)<0, tf=false; return; end
    else
        t=q(i)/p(i);
        if p(i)<0
            if t>u2, tf=false; return; end
            u1=max(u1,t);
        else
            if t<u1, tf=false; return; end
            u2=min(u2,t);
        end
    end
end
tf=true;
end
