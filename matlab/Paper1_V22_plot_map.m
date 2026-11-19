function Paper1_V22_plot_map(mapId)
cfg=Paper1_V22_config();map=Paper1_V22_load_map(mapId,cfg);figure;hold on;axis equal;xlim([0 50]);ylim([0 50]);
for i=1:numel(map.obstacles),o=map.obstacles(i);if strcmpi(o.type,'circle'),rectangle('Position',[o.cx-o.r,o.cy-o.r,2*o.r,2*o.r],'Curvature',[1 1]);else,rectangle('Position',[o.xmin,o.ymin,o.xmax-o.xmin,o.ymax-o.ymin]);end,end
L=ufln_landmarks(map,cfg);scatter(L(:,1),L(:,2),12,'.');plot(map.reference_path(:,1),map.reference_path(:,2),'--');plot(map.start(1),map.start(2),'o');plot(map.goal(1),map.goal(2),'x');title(map.id);xlabel('x');ylabel('y');
end
