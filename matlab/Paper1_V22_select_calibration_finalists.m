function Paper1_V22_select_calibration_finalists()
% Paper1_V22_select_calibration_finalists
% Select two finalists per tunable planner from the SCREEN stage.
%
% Selection rule (pre-confirmation):
%   1) highest observed success rate;
%   2) among candidates at that success rate, path ratios within 0.5% of
%      the best median path ratio are treated as practically equivalent;
%   3) within that practical-equivalence set, lower median proposer time
%      is preferred.
%
% The rule is applied sequentially to choose finalist 1 and finalist 2.
% This avoids choosing candidates on scientifically negligible floating-
% point differences in path ratio (e.g., 0.9966 vs 0.9968).
%
% This script does not modify Calibration_Raw.csv.

cfg = Paper1_V22_config();

rawFile = fullfile(cfg.calibrationDir,'Calibration_Raw.csv');
if ~exist(rawFile,'file')
    error('Calibration_Raw.csv not found. Run screen calibration first.');
end

R = readtable(rawFile,'TextType','string');

requiredVars = ["planner","candidate_id","calibration_stage","success", ...
                "path_ratio","proposer_time_total_s"];
missingVars = requiredVars(~ismember(requiredVars,string(R.Properties.VariableNames)));
if ~isempty(missingVars)
    error('Calibration_Raw.csv is missing required column(s): %s', ...
        strjoin(cellstr(missingVars),', '));
end

G = Paper1_V22_calibration_grid();
planners = fieldnames(G);

% Practical-equivalence threshold for the task-normalized reference-route ratio.
pathRelTol = 0.005; % 0.5%

F = struct();
rows = cell(0,7);

fprintf('\n===== UFLN V2.2 SCREEN FINALIST SELECTION =====\n');
fprintf('Rule: success first; path ratios within %.2f%% treated as equivalent; then proposer time.\n\n', ...
    100*pathRelTol);

for pi = 1:numel(planners)

    p = planners{pi};
    stats = struct('ci',{},'n',{},'succ',{},'pr',{},'pt',{});

    for ci = 1:numel(G.(p))

        Q = R( ...
            R.planner == string(p) & ...
            R.candidate_id == ci & ...
            R.calibration_stage == "SCREEN", :);

        if isempty(Q)
            error('Missing SCREEN records for %s candidate %d.',p,ci);
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

        stats(end+1) = struct('ci',ci,'n',height(Q), ...
            'succ',succ,'pr',pr,'pt',pt); %#ok<AGROW>

        rows = [rows; {string(p),ci,height(Q),succ,pr,pt,false}]; %#ok<AGROW>

        fprintf('%-8s C%d | n=%3d | success=%6.2f%% | med path ratio=%8.4f | med proposer=%9.5f s\n', ...
            p, ci, height(Q), 100*succ, pr, pt);
    end

    chosen = zeros(1,2);
    available = true(1,numel(stats));

    for pick = 1:2

        idx = find(available);

        % 1) Highest success among remaining candidates.
        succVals = [stats(idx).succ];
        bestSucc = max(succVals);
        idxSucc = idx(abs(succVals - bestSucc) < 1e-12);

        % 2) Best path ratio at that success level.
        prVals = [stats(idxSucc).pr];
        bestPr = min(prVals);

        if isfinite(bestPr)
            % Relative practical-equivalence band.
            denom = max(abs(bestPr),1e-12);
            relGap = (prVals - bestPr) ./ denom;
            idxEq = idxSucc(relGap <= pathRelTol + 1e-12);
        else
            idxEq = idxSucc;
        end

        % 3) Fastest proposer among path-equivalent candidates.
        ptVals = [stats(idxEq).pt];
        [~,k] = min(ptVals);
        win = idxEq(k);

        chosen(pick) = stats(win).ci;
        available(win) = false;
    end

    F.(p) = chosen;

    fprintf('  -> finalists for %-8s: C%d and C%d\n\n', ...
        p, chosen(1), chosen(2));

    % Mark finalists in summary rows.
    for rr = 1:size(rows,1)
        if rows{rr,1} == string(p) && any(rows{rr,2} == chosen)
            rows{rr,7} = true;
        end
    end
end

finalistFile = fullfile(cfg.calibrationDir,'Calibration_Finalists.json');
fid = fopen(finalistFile,'w');
if fid < 0
    error('Could not open %s for writing.',finalistFile);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',jsonencode(F,'PrettyPrint',true));

T = cell2table(rows,'VariableNames', ...
    {'planner','candidate_id','n_screen','success_rate', ...
     'median_reference_route_ratio','median_proposer_time_s','selected_finalist'});

summaryFile = fullfile(cfg.calibrationDir,'Calibration_Screen_Summary.csv');
writetable(T,summaryFile);

fprintf('Finalists written to:\n  %s\n',finalistFile);
fprintf('Screen summary written to:\n  %s\n',summaryFile);
fprintf('Review both files before running confirm calibration.\n');

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
