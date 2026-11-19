function cfg = Paper1_V22_config()
% UFLN 1.0 / Paper1 Journal V2.2.1 candidate. DO NOT freeze until calibration is selected.
codeDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(codeDir);
cfg.version = "UFLN_1.0_V2_2_1_candidate";
cfg.corpus_version = "UFLN_V2_2";
cfg.rootDir = rootDir;
cfg.codeDir = codeDir;
cfg.corpusDir = fullfile(rootDir,'03_Corpus');
cfg.scheduleDir = fullfile(rootDir,'05_Schedules');
cfg.rawDir = fullfile(rootDir,'06_Raw_Results');
cfg.traceDir = fullfile(cfg.rawDir,'Traces');
cfg.calibrationDir = fullfile(rootDir,'04_Calibration');

cfg.workspace = [0 50 0 50];
cfg.robot.radius = 0.35;
cfg.robot.v_max = 1.0;
cfg.robot.w_max = 1.5;
cfg.robot.a_v_max = 1.0;
cfg.robot.a_w_max = 2.5;
cfg.controller.dt = 0.10;
cfg.controller.k_rho = 1.4;
cfg.controller.k_alpha = 2.6;
cfg.controller.align_angle = deg2rad(25);
cfg.controller.waypoint_tol = 0.12;
cfg.controller.goal_tol = 0.50;
cfg.controller.landmark_tol = 0.65;
cfg.controller.max_control_steps_per_waypoint = 250;
cfg.controller.stop_at_waypoint = true;
cfg.controller.safety_rotate_only = true;

cfg.sensor.fov_full_deg = 120;
cfg.sensor.range = 15.0;
cfg.sensor.scan_increment_deg = 15;
cfg.sensor.scan_w = 0.8;
cfg.sensor.landmark_mode = "med"; % low, med, high

cfg.safety.margin = 0.20;
cfg.safety.clearance_target = 1.00;
cfg.execution.r_plan = 3.0;
cfg.execution.r_exec = 1.0;
cfg.execution.max_nav_steps = 700;
cfg.execution.max_landmark_switches = 250;
cfg.execution.fallback_offsets_deg = [0 20 -20 40 -40 60 -60 90 -90 120 -120 180];

% Normalized common objective for ACO/BA/FA/SAFA.
cfg.objective.w_progress = 0.50;
cfg.objective.w_clearance = 0.25;
cfg.objective.w_step = 0.15;
cfg.objective.w_heading = 0.10;
cfg.objective.eval_budget = 2000;

% Planner defaults. Calibration can override these through Selected_Planner_Params.json.
cfg.planners.ACO.samples = 25; cfg.planners.ACO.archive = 8; cfg.planners.ACO.q = 0.5; cfg.planners.ACO.sigma_frac = 0.25;
cfg.planners.BA.population = 50; cfg.planners.BA.fmin = 0; cfg.planners.BA.fmax = 2; cfg.planners.BA.loudness = 0.9; cfg.planners.BA.pulse = 0.5; cfg.planners.BA.local_frac = 0.12;
cfg.planners.FA.population = 50; cfg.planners.FA.beta0 = 1.5; cfg.planners.FA.gamma = 0.7; cfg.planners.FA.alpha0 = 0.20; cfg.planners.FA.alpha_damp = 0.92; cfg.planners.FA.random_frac = 0.20;
cfg.planners.SAFA = cfg.planners.FA; cfg.planners.SAFA.drift_frac = 0.15;
cfg.planners.DVWP.k_att = 1.0; cfg.planners.DVWP.k_rep = 0.7; cfg.planners.DVWP.d0 = 5.0; cfg.planners.DVWP.rep_cap = 3.0; cfg.planners.DVWP.step_frac = 0.30;
cfg.planners.RRT.step = 0.75; cfg.planners.RRT.goal_bias = 0.15; cfg.planners.RRT.max_nodes = 500;
cfg.planners.GRAPH.grid = 0.50; cfg.planners.GRAPH.connect = 0.72;

cfg.experiment.main_stochastic_seeds = 4000:4029;
cfg.experiment.calibration_screen_seeds = 5000:5004;
cfg.experiment.calibration_confirm_seeds = 5000:5009;
cfg.experiment.calibration_seeds = cfg.experiment.calibration_confirm_seeds; % compatibility
cfg.experiment.trace_representative_seed = 4000;
cfg.experiment.trace_policy = "failures_plus_representatives";

% Apply calibration selection if it exists.
selFile = fullfile(cfg.calibrationDir,'Selected_Planner_Params.json');
if exist(selFile,'file')
    S = jsondecode(fileread(selFile));
    names = fieldnames(S);
    for i=1:numel(names)
        nm = names{i};
        if isfield(cfg.planners,nm)
            cfg.planners.(nm) = mergeStruct(cfg.planners.(nm),S.(nm));
        end
    end
end
end

function out = mergeStruct(a,b)
out=a; fn=fieldnames(b);
for k=1:numel(fn), out.(fn{k})=b.(fn{k}); end
end
