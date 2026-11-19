function Paper1_V22_select_calibration()
% Paper1_V22_select_calibration
% Final parameter selection after CONFIRM calibration for UFLN V2.2.1.
%
% Selection rule:
%   1) highest observed success rate;
%   2) among candidates at that success rate, path ratios within 0.5% of
%      the best median reference-route ratio are treated as practically
%      equivalent;
%   3) within that practical-equivalence set, lower median proposer time
%      is preferred.
%
% SCREEN records that belong to the confirm design are reused, so this
% script intentionally uses all unique records for each finalist.

cfg = Paper1_V22_config();
rawFile = fullfile(cfg.calibrationDir,'Calibration_Raw.csv');
finalistsFile = fullfile(cfg.calibrationDir,'Calibration_Finalists.json');

if ~exist(rawFile,'file') || ~exist(finalistsFile,'file')
    error('Complete SCREEN, finalist selection, and CONFIRM calibration first.');
end

R = readtable(rawFile,'TextType','string');
F = jsondecode(fileread(finalistsFile));
G = Paper1_V22_calibration_grid();

requiredVars = ["planner","candidate_id","success","path_ratio", ...
                "proposer_time_total_s","record_key"];
missingVars = requiredVars(~ismember(requiredVars,string(R.Properties.VariableNames)));
if ~isempty(missingVars)
    error('Calibration_Raw.csv is missing required column(s): %s', ...
        strjoin(cellstr(missingVars),', '));
end

if numel(unique(R.record_key)) ~= height(R)
    error('Calibration_Raw.csv contains duplicate record_key values.');
end

planners = fieldnames(G);
pathRelTol = 0.005; % 0.5%
selectedParams = struct();
selectedCandidates = struct();
summaryRows = cell(0,8);

fprintf('\n===== UFLN V2.2 FINAL CALIBRATION SELECTION =====\n');
fprintf(['Rule: success first; reference-route ratios within %.2f%% ' ...
         'treated as equivalent; then proposer time.\n\n'],100*pathRelTol);

for pi = 1:numel(planners)
    p = planners{pi};
    if ~isfield(F,p)
        error('Calibration_Finalists.json has no entry for planner %s.',p);
    end

    finalistIds = double(F.(p));
    finalistIds = finalistIds(:)';
    if numel(finalistIds) ~= 2
        error('%s must have exactly two finalists; found %d.',p,numel(finalistIds));
    end

    stats = struct('ci',{},'n',{},'succ',{},'pr',{},'pt',{});

    for k = 1:numel(finalistIds)
        ci = finalistIds(k);
        Q = R(R.planner == string(p) & R.candidate_id == ci,:);

        if any(strcmp(p,{'ACO','BA','FA','SAFA','RRT'}))
            expected = 15 * numel(cfg.experiment.calibration_confirm_seeds);
        else
            expected = 15;
        end

        if height(Q) ~= expected
            error('%s candidate %d has %d unique records; expected %d.', ...
                p,ci,height(Q),expected);
        end

        successMask = toLogicalSuccess(Q.success);
        succ = mean(successMask);
        q = Q(successMask,:);

        if isempty(q)
            pr = inf;
            pt = inf;
        else
            pr = median(q.path_ratio,'omitnan');
            pt = median(q.proposer_time_total_s,'omitnan');
            if isnan(pr), pr = inf; end
            if isnan(pt), pt = inf; end
        end

        stats(end+1) = struct('ci',ci,'n',height(Q),'succ',succ,'pr',pr,'pt',pt); %#ok<AGROW>
        summaryRows = [summaryRows; ...
            {string(p),ci,height(Q),succ,pr,pt,false,""}]; %#ok<AGROW>

        fprintf(['%-8s C%d | n=%3d | success=%6.2f%% | ' ...
                 'med ref-route ratio=%8.4f | med proposer=%9.5f s\n'], ...
            p,ci,height(Q),100*succ,pr,pt);
    end

    succVals = [stats.succ];
    bestSucc = max(succVals);
    idxSucc = find(abs(succVals-bestSucc) < 1e-12);

    prVals = [stats(idxSucc).pr];
    bestPr = min(prVals);
    if isfinite(bestPr)
        denom = max(abs(bestPr),1e-12);
        relGap = (prVals-bestPr)./denom;
        idxEq = idxSucc(relGap <= pathRelTol + 1e-12);
    else
        idxEq = idxSucc;
    end

    ptVals = [stats(idxEq).pt];
    [~,j] = min(ptVals);
    winIdx = idxEq(j);
    chosenCi = stats(winIdx).ci;

    selectedParams.(p) = G.(p){chosenCi};
    selectedCandidates.(p) = chosenCi;
    fprintf('  -> selected for %-8s: C%d\n\n',p,chosenCi);

    for rr = 1:size(summaryRows,1)
        if summaryRows{rr,1} == string(p) && summaryRows{rr,2} == chosenCi
            summaryRows{rr,7} = true;
            summaryRows{rr,8} = ...
                "success first; 0.5% reference-route equivalence; proposer time";
        end
    end
end

selectedParamsFile = fullfile(cfg.calibrationDir,'Selected_Planner_Params.json');
fid = fopen(selectedParamsFile,'w');
if fid < 0, error('Could not open %s for writing.',selectedParamsFile); end
fprintf(fid,'%s',jsonencode(selectedParams,'PrettyPrint',true));
fclose(fid);

selectedCandidatesFile = fullfile(cfg.calibrationDir,'Calibration_Selected_Candidates.json');
fid = fopen(selectedCandidatesFile,'w');
if fid < 0, error('Could not open %s for writing.',selectedCandidatesFile); end
fprintf(fid,'%s',jsonencode(selectedCandidates,'PrettyPrint',true));
fclose(fid);

T = cell2table(summaryRows,'VariableNames', ...
    {'planner','candidate_id','n_confirm_design','success_rate', ...
     'median_reference_route_ratio','median_proposer_time_s', ...
     'selected','selection_rule'});
summaryFile = fullfile(cfg.calibrationDir,'Calibration_Confirm_Summary.csv');
writetable(T,summaryFile);

fprintf('Final selected parameters written to:\n  %s\n',selectedParamsFile);
fprintf('Selected candidate IDs written to:\n  %s\n',selectedCandidatesFile);
fprintf('Confirmation summary written to:\n  %s\n',summaryFile);
fprintf('\nNEXT: re-run QUICK and DEEP validation under the selected parameters.\n');
fprintf('Do not freeze or start the 90-map evaluation until those pass.\n');
end

function mask = toLogicalSuccess(x)
if islogical(x)
    mask = x;
elseif isnumeric(x)
    mask = isfinite(x) & (x ~= 0);
else
    sx = lower(strtrim(string(x)));
    mask = sx == "1" | sx == "true" | sx == "yes" | sx == "success";
end
end
