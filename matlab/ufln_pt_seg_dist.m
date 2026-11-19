function d = ufln_pt_seg_dist(p,a,b)
v=b-a; den=dot(v,v);
if den<1e-14, d=norm(p-a); return; end
t=dot(p-a,v)/den; t=max(0,min(1,t)); q=a+t*v; d=norm(p-q);
end
