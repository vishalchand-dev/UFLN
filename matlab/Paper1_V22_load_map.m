function map = Paper1_V22_load_map(mapId,cfg)
folders = {fullfile(cfg.corpusDir,'Evaluation'),fullfile(cfg.corpusDir,'Calibration'),fullfile(cfg.corpusDir,'Diagnostic'),fullfile(cfg.corpusDir,'Validation')};
file="";
for i=1:numel(folders)
    f=fullfile(folders{i},mapId+".json");
    if exist(f,'file'), file=f; break; end
end
if strlength(file)==0, error('Map not found: %s',mapId); end
map=jsondecode(fileread(file));
map.id=string(map.id); map.split=string(map.split); map.difficulty=string(map.difficulty);
if isfield(map,'corpus_version'), map.corpus_version=string(map.corpus_version); else, error('Map %s missing corpus_version.',mapId); end
if map.corpus_version~=cfg.corpus_version, error('Map %s has corpus version %s, expected %s.',mapId,map.corpus_version,cfg.corpus_version); end
% MATLAB may decode singleton arrays oddly; normalize numeric arrays.
map.start=double(map.start(:))'; map.goal=double(map.goal(:))';
map.reference_path=double(map.reference_path);
map.landmarks_low=double(map.landmarks_low);
map.landmarks_med=double(map.landmarks_med);
map.landmarks_high=double(map.landmarks_high);
if isfield(map,'backbone_landmarks'), map.backbone_landmarks=double(map.backbone_landmarks); end
end
