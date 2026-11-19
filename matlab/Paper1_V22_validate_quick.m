function ok = Paper1_V22_validate_quick()
% Fast structural validation. No evaluation-map planner performance is run.
cfg=Paper1_V22_config();addpath(cfg.codeDir,fullfile(cfg.codeDir,'planners'),'-begin');ok=true;
flag=fullfile(cfg.rootDir,'10_Reproducibility','QUICK_VALIDATION_PASS.txt');if exist(flag,'file'),delete(flag);end
fprintf('===== UFLN V2.2.1 QUICK VALIDATION =====\n');
t0=tic;
try
    E=readtable(fullfile(cfg.corpusDir,'Evaluation','evaluation_manifest.csv'),'TextType','string');
    C=readtable(fullfile(cfg.corpusDir,'Calibration','calibration_manifest.csv'),'TextType','string');
    D=readtable(fullfile(cfg.corpusDir,'Diagnostic','diagnostic_manifest.csv'),'TextType','string');
    assert(height(E)==90 && height(C)==15 && height(D)==15);
    assert(sum(E.difficulty=="easy")==30 && sum(E.difficulty=="medium")==30 && sum(E.difficulty=="hard")==30);
    fprintf('PASS corpus counts and 30/30/30 evaluation balance\n');
    % Geometry + landmark backbone audit. This checks all maps without executing planners.
    ids=[C.id;E.id];
    for i=1:numel(ids)
        map=Paper1_V22_load_map(ids(i),cfg);
        assert(ufln_point_clearance(map.start(1:2),map,cfg,false)>0);
        assert(ufln_point_clearance(map.goal,map,cfg,false)>0);
        assert(map.reference_length>=map.euclidean_length-1e-8);
        for k=1:size(map.reference_path,1)-1
            assert(ufln_segment_safe(map.reference_path(k,:),map.reference_path(k+1,:),map,cfg));
        end
        R=ufln_validate_landmark_backbone(map,cfg);assert(R.ok,char(R.reason));
    end
    fprintf('PASS all 105 calibration/evaluation geometry + landmark-backbone audits\n');
    % Difficulty strata should be ordered by geometry score in aggregate.
    medE=median(E.difficulty_score(E.difficulty=="easy"));medM=median(E.difficulty_score(E.difficulty=="medium"));medH=median(E.difficulty_score(E.difficulty=="hard"));
    assert(medE<medM && medM<medH);fprintf('PASS difficulty-score ordering easy < medium < hard\n');
    % Dedicated validation map only. Evaluation maps are never used for planner smoke tests.
    map=Paper1_V22_load_map("VAL_SMOKE",cfg);
    assert(ufln_segment_safe(map.start(1:2),map.reference_path(2,:),map,cfg));
    % Reduced-budget proposer smoke test for speed; scientific configuration is unchanged.
    cv=validationCfg(cfg);L=ufln_landmarks(map,cv);visited=false(size(L,1),1);idx=ufln_select_landmark(map.start,L,map,cv,visited);assert(idx>0);lm=L(idx,:);
    planners=["GREEDY","DVWP","DIJKSTRA","ASTAR","ACO","BA","FA","SAFA","RRT"];
    for p=planners
        rng(777,'twister');f=ufln_get_planner(p);[z,dg]=f(map.start,lm,map,cv);
        assert(all(isfinite(z)));assert(norm(z-map.start(1:2))<=cv.execution.r_plan+1e-8);assert(isfield(dg,'proposer_time_s'));
    end
    fprintf('PASS all nine proposer contracts on dedicated validation map\n');
    % Lightweight tracker contract test. This catches output-assignment and
    % interface errors without running the experimental corpus.
    state0=map.start;wpT=state0(1:2)+[0.5 0];assert(ufln_segment_safe(state0(1:2),wpT,map,cv));
    [~,segT,okT,reasonT,~]=ufln_track_waypoint(state0,wpT,map,cv,[0 0]);
    assert(isnumeric(segT));assert(isempty(segT) || size(segT,2)==7);assert(okT,char(reasonT));
    fprintf('PASS shared tracker output/contract smoke test\n');
    rng(777,'twister');f=ufln_get_planner("ACO");[z1,~]=f(map.start,lm,map,cv);rng(777,'twister');[z2,~]=f(map.start,lm,map,cv);assert(norm(z1-z2)<1e-12);
    rng(1);f=ufln_get_planner("ASTAR");[a,~]=f(map.start,lm,map,cv);rng(999);[b,~]=f(map.start,lm,map,cv);assert(norm(a-b)<1e-12);
    fprintf('PASS proposer-level stochastic reproducibility and deterministic RNG invariance\n');
catch ME
    ok=false;fprintf(2,'QUICK VALIDATION FAIL: %s\n',ME.message);fprintf(2,'%s\n',getReport(ME,'extended'));
end
if ok,fprintf('QUICK VALIDATION PASS (%.1f s)\n',toc(t0));fid=fopen(flag,'w');fprintf(fid,'Version: %s\nTime: %s\n',cfg.version,string(datetime('now')));fclose(fid);else,fprintf(2,'QUICK VALIDATION FAIL\n');end
end

function c=validationCfg(c)
c.objective.eval_budget=60;
c.planners.ACO.samples=10;c.planners.ACO.archive=5;
c.planners.BA.population=10;c.planners.FA.population=10;c.planners.SAFA.population=10;c.planners.RRT.max_nodes=80;
end
