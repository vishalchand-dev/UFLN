function ok = Paper1_V22_validate_deep()
% End-to-end smoke validation on a dedicated validation map only.
% Run once after quick validation and again before freezing the final experiment.
cfg=Paper1_V22_config();addpath(cfg.codeDir,fullfile(cfg.codeDir,'planners'),'-begin');ok=true;
flag=fullfile(cfg.rootDir,'10_Reproducibility','DEEP_VALIDATION_PASS.txt');if exist(flag,'file'),delete(flag);end
fprintf('===== UFLN V2.2.1 DEEP VALIDATION =====\n');t0=tic;
try
    cv=cfg;cv.objective.eval_budget=120;cv.execution.max_nav_steps=80;cv.execution.max_landmark_switches=40;
    cv.planners.ACO.samples=12;cv.planners.ACO.archive=5;cv.planners.BA.population=12;cv.planners.FA.population=12;cv.planners.SAFA.population=12;cv.planners.RRT.max_nodes=120;
    map=Paper1_V22_load_map("VAL_SMOKE",cv);
    planners=["GREEDY","DVWP","DIJKSTRA","ASTAR","ACO","BA","FA","SAFA","RRT"];
    for p=planners
        fprintf('  testing %-8s ... ',p);drawnow;
        sd=0;if any(p==["ACO","BA","FA","SAFA","RRT"]),sd=777;end
        [r,tr]=ufln_run_one(map,cv,p,sd,"DEEP|"+p);
        assert(size(tr.data,2)==15);assert(r.min_clearance>=-1e-9);assert(~(r.termination_reason=="TRACKING_SAFETY_GUARD"));
        fprintf('success=%d term=%s\n',r.success,r.termination_reason);
    end
    [r1,~]=ufln_run_one(map,cv,"ACO",987,"REP1");[r2,~]=ufln_run_one(map,cv,"ACO",987,"REP2");
    assert(r1.success==r2.success);assert(abs(r1.path_length-r2.path_length)<1e-10);assert(r1.termination_reason==r2.termination_reason);
    fprintf('PASS end-to-end fixed-seed reproducibility\n');
catch ME
    ok=false;fprintf(2,'DEEP VALIDATION FAIL: %s\n',ME.message);fprintf(2,'%s\n',getReport(ME,'extended'));
end
if ok,fprintf('DEEP VALIDATION PASS (%.1f s)\n',toc(t0));fid=fopen(flag,'w');fprintf(fid,'Version: %s\nTime: %s\n',cfg.version,string(datetime('now')));fclose(fid);else,fprintf(2,'DEEP VALIDATION FAIL\n');end
end
