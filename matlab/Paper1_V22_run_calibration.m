function Paper1_V22_run_calibration(mode)
% Two-stage, resumable calibration.
%   Paper1_V22_run_calibration("screen")  : all 4 candidates on 6 maps x 5 seeds
%   Paper1_V22_run_calibration("confirm") : 2 finalists on all 15 maps x 10 seeds
% Existing record keys are reused, so finalist screen runs are not repeated.
if nargin<1, mode="screen"; end
mode=lower(string(mode));
cfg0=Paper1_V22_config();addpath(cfg0.codeDir,fullfile(cfg0.codeDir,'planners'),'-begin');G=Paper1_V22_calibration_grid();
M=readtable(fullfile(cfg0.corpusDir,'Calibration','calibration_manifest.csv'),'TextType','string');
if mode=="screen"
    ids=string(strtrim(splitlines(fileread(fullfile(cfg0.calibrationDir,'Screening_Map_IDs.txt')))));ids(ids=="")=[];
    M=M(ismember(M.id,ids),:);seedsStoch=cfg0.experiment.calibration_screen_seeds;
    candMap=struct();pl=fieldnames(G);for i=1:numel(pl),candMap.(pl{i})=1:numel(G.(pl{i}));end
elseif mode=="confirm"
    ff=fullfile(cfg0.calibrationDir,'Calibration_Finalists.json');if ~exist(ff,'file'),error('Run Paper1_V22_select_calibration_finalists first.');end
    F=jsondecode(fileread(ff));seedsStoch=cfg0.experiment.calibration_confirm_seeds;candMap=F;
else
    error('mode must be "screen" or "confirm".');
end
out=fullfile(cfg0.calibrationDir,'Calibration_Raw.csv');completed=strings(0,1);
if exist(out,'file'),R=readtable(out,'TextType','string');if ~isempty(R),completed=unique(R.record_key);end,end
planners=fieldnames(G);plannedKeys=strings(0,1);
for pi=1:numel(planners)
    p=planners{pi};idsCand=double(candMap.(p));
    if any(strcmp(p,{'ACO','BA','FA','SAFA','RRT'})),seeds=seedsStoch;else,seeds=0;end
    for ci=idsCand(:)'
        for mi=1:height(M),for sd=seeds,plannedKeys(end+1,1)="CAL|"+p+"|C"+ci+"|"+M.id(mi)+"|"+sd;end,end %#ok<AGROW>
    end
end
remaining=sum(~ismember(plannedKeys,completed));fprintf('\n===== UFLN V2.2 CALIBRATION %s =====\n',upper(mode));fprintf('Stage records: %d | already present: %d | to run: %d\n',numel(plannedKeys),numel(plannedKeys)-remaining,remaining);
t0=tic;session=0;
for pi=1:numel(planners)
    p=planners{pi};idsCand=double(candMap.(p));
    for ci=idsCand(:)'
        cfg=cfg0;cfg.planners.(p)=mergeStruct(cfg.planners.(p),G.(p){ci});fprintf('--- %s candidate %d ---\n',p,ci);
        for mi=1:height(M)
            map=Paper1_V22_load_map(M.id(mi),cfg);
            if any(strcmp(p,{'ACO','BA','FA','SAFA','RRT'})),seeds=seedsStoch;else,seeds=0;end
            for seed=seeds
                key="CAL|"+p+"|C"+ci+"|"+map.id+"|"+seed;if any(completed==key),continue;end
                [r,~]=ufln_run_one(map,cfg,p,seed,key);r.candidate_id=ci;r.calibration_stage=upper(mode);
                T=Paper1_V22_result_to_table(r,"CALIBRATION","PATH",1);Paper1_V22_append_table(out,T);
                completed(end+1,1)=key;session=session+1;
                if mod(session,5)==0 || session==remaining
                    el=toc(t0);eta=el/max(session,1)*max(remaining-session,0);
                    fprintf('%s C%d | map %d/%d %s | seed %d | session %d/%d | elapsed %s | ETA ~%s\n',p,ci,mi,height(M),map.id,seed,session,remaining,fmt(el),fmt(eta));drawnow;
                end
            end
        end
    end
end
fprintf('===== %s CALIBRATION STAGE COMPLETE =====\n',upper(mode));fprintf('Raw: %s\n',out);
end
function o=mergeStruct(a,b),o=a;f=fieldnames(b);for k=1:numel(f),o.(f{k})=b.(f{k});end,end
function s=fmt(x),x=max(0,round(x));s=sprintf('%02d:%02d:%02d',floor(x/3600),floor(mod(x,3600)/60),mod(x,60));end
