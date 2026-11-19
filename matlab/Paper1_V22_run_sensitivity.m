function Paper1_V22_run_sensitivity()
cfg0=Paper1_V22_config();C=readtable(fullfile(cfg0.scheduleDir,'sensitivity_conditions.csv'),'TextType','string');ids=splitlines(string(fileread(fullfile(cfg0.scheduleDir,'sensitivity_map_ids.txt'))));ids=ids(strlength(ids)>0);
out=fullfile(cfg0.rawDir,'Sensitivity_Raw.csv');completed=strings(0,1);if exist(out,'file'),R=readtable(out,'TextType','string');completed=unique(R.record_key);end
planners=["GREEDY","DVWP","DIJKSTRA","ASTAR","ACO","BA","FA","SAFA","RRT"];
% Compute total unique schedule size for progress display.
planned=0;for ci=1:height(C),for mi=1:numel(ids),for p=planners,if any(p==["ACO","BA","FA","SAFA","RRT"]),planned=planned+10;else,planned=planned+1;end,end,end,end
fprintf('\n===== UFLN V2.2 SENSITIVITY | planned=%d =====\n',planned);t0=tic;session=0;
for ci=1:height(C)
    cfg=Paper1_V22_apply_sensitivity(cfg0,C(ci,:));
    for mi=1:numel(ids)
        map=Paper1_V22_load_map(ids(mi),cfg);
        for p=planners
            seeds=0;if any(p==["ACO","BA","FA","SAFA","RRT"]),seeds=4000:4009;end
            for seed=seeds
                key="SENS|"+C.condition_id(ci)+"|"+map.id+"|"+p+"|"+seed;if any(completed==key),continue;end
                [r,tr]=ufln_run_one(map,cfg,p,seed,key);r.condition_id=C.condition_id(ci);T=Paper1_V22_result_to_table(r,"SENSITIVITY","PATH",1);Paper1_V22_append_table(out,T);completed(end+1,1)=key;session=session+1;
                if ~r.success,safeKey=regexprep(char(key),'[^A-Za-z0-9_-]','_');save(fullfile(cfg.traceDir,[safeKey '.mat']),'tr','r','map','-v7.3');end
                if mod(session,10)==0
                    fprintf('Sensitivity session %d | condition %s | %s %s | elapsed %.1f min\n',session,C.condition_id(ci),map.id,p,toc(t0)/60);drawnow;
                end
            end
        end
    end
    fprintf('Sensitivity condition %s complete.\n',C.condition_id(ci));
end
end
