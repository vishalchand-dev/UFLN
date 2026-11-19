function d = ufln_point_rect_signed(p,xmin,xmax,ymin,ymax)
% Signed Euclidean distance to an axis-aligned rectangle.
% Positive outside, zero on boundary, negative inside.
x=p(1); y=p(2);
dx=max([xmin-x,0,x-xmax]);
dy=max([ymin-y,0,y-ymax]);
if dx>0 || dy>0
    d=hypot(dx,dy);
else
    d=-min([x-xmin,xmax-x,y-ymin,ymax-y]);
end
end
