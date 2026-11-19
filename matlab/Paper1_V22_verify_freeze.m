function Paper1_V22_verify_freeze()
cfg=Paper1_V22_config();repDir=fullfile(cfg.rootDir,'10_Reproducibility');flag=fullfile(repDir,'FREEZE_CONFIRMED.txt');
if ~exist(flag,'file'),error('Experiment is not frozen. Complete calibration, validation and Freeze_Experiment.ps1 first.');end
script=fullfile(repDir,'Verify_Hashes.ps1');
cmd=sprintf('powershell -NoProfile -ExecutionPolicy Bypass -File "%s"',script);
[status,out]=system(cmd);fprintf('%s',out);if status~=0,error('Frozen-file verification failed. Do not run the experiment.');end
end
