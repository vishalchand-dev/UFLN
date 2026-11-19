function idx = ufln_select_landmark(state,L,map,cfg,visited)
[idxs,~]=ufln_visible_landmarks(state,L,map,cfg,visited);
if isempty(idxs), idx=0; return; end
% If the goal is present and visible, choose it.
dg=vecnorm(L(idxs,:)-map.goal,2,2);
[bestGoal,kg]=min(dg);
if bestGoal <= 1e-8, idx=idxs(kg); return; end
% Otherwise choose the visible unvisited landmark closest to final goal.
[~,k]=min(dg); idx=idxs(k);
end
