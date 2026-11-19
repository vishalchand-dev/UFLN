function d = ufln_segment_rect_distance(a,b,xmin,xmax,ymin,ymax)
% Exact minimum Euclidean distance between a line segment and an AABB.
if ufln_segment_intersects_rect(a,b,xmin,xmax,ymin,ymax)
    d=0; return;
end
corners=[xmin ymin; xmax ymin; xmax ymax; xmin ymax];
d=min(max(ufln_point_rect_signed(a,xmin,xmax,ymin,ymax),0), ...
      max(ufln_point_rect_signed(b,xmin,xmax,ymin,ymax),0));
for k=1:4
    d=min(d,ufln_pt_seg_dist(corners(k,:),a,b));
end
end
