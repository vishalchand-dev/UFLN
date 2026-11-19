function Paper1_V22_run_experiment(mode)
cfg=Paper1_V22_config();addpath(cfg.codeDir,fullfile(cfg.codeDir,'planners'),'-begin');
mode=lower(string(mode));
switch mode
    case "main_path", sched=fullfile(cfg.scheduleDir,'main_path_schedule.csv'); phase="MAIN";
    case "main_timing", sched=fullfile(cfg.scheduleDir,'main_timing_schedule.csv'); phase="MAIN";
    case "diagnostic_path", sched=fullfile(cfg.scheduleDir,'diagnostic_path_schedule.csv'); phase="DIAGNOSTIC";
    case "diagnostic_timing", sched=fullfile(cfg.scheduleDir,'diagnostic_timing_schedule.csv'); phase="DIAGNOSTIC";
    case "sensitivity", Paper1_V22_verify_freeze();Paper1_V22_run_sensitivity;return;
    otherwise,error('Unknown mode. Use main_path, main_timing, diagnostic_path, diagnostic_timing, sensitivity.');
end
Paper1_V22_verify_freeze();
S=readtable(sched,'TextType','string');outFile=fullfile(cfg.rawDir,'Results_Raw.csv');completed=strings(0,1);
if exist(outFile,'file'),R=readtable(outFile,'TextType','string');if any(strcmp(R.Properties.VariableNames,'record_key')),completed=unique(R.record_key);end,end
remaining=sum(~ismember(S.record_key,completed));fprintf('\n===== %s | scheduled=%d | already complete=%d | remaining=%d =====\n',upper(mode),height(S),height(S)-remaining,remaining);
t0=tic;session=0;
for i=1:height(S)
    if any(completed==S.record_key(i)),continue;end
    map=Paper1_V22_load_map(S.map_id(i),cfg);recType=string(S.record_type(i));
    if recType=="TIMING" && S.rep(i)==1
        ufln_run_one(map,cfg,S.planner(i),0,"WARMUP|"+S.map_id(i)+"|"+S.planner(i));
    end
    [r,tr]=ufln_run_one(map,cfg,S.planner(i),S.seed(i),S.record_key(i));
    T=Paper1_V22_result_to_table(r,phase,recType,S.rep(i));Paper1_V22_append_table(outFile,T);completed(end+1,1)=S.record_key(i);session=session+1;
    if Paper1_V22_should_save_trace(r,recType,cfg)
        safeKey=regexprep(char(S.record_key(i)),'[^A-Za-z0-9_-]','_');save(fullfile(cfg.traceDir,[safeKey '.mat']),'tr','r','map','-v7.3');
    end
    if mod(session,10)==0 || session==remaining
        el=toc(t0);eta=el/max(session,1)*max(remaining-session,0);
        fprintf('%s | session %d/%d | schedule row %d/%d | %s %s | elapsed %s | ETA ~%s\n',upper(mode),session,remaining,i,height(S),S.map_id(i),S.planner(i),fmt(el),fmt(eta));drawnow;
    end
end
fprintf('Requested phase "%s" completed. Raw results: %s\n',mode,outFile);
end
function s=fmt(x),x=max(0,round(x));s=sprintf('%02d:%02d:%02d',floor(x/3600),floor(mod(x,3600)/60),mod(x,60));end
