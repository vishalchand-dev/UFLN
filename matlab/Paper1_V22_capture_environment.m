function Paper1_V22_capture_environment()
cfg=Paper1_V22_config();out=fullfile(cfg.rootDir,'10_Reproducibility','Environment_Captured.txt');fid=fopen(out,'w');
fprintf(fid,'Captured: %s\n',string(datetime('now')));
fprintf(fid,'UFLN package: %s\n',cfg.version);fprintf(fid,'MATLAB: %s\n',version);fprintf(fid,'Computer: %s\n',computer);
try,fprintf(fid,'MATLAB numcores: %d\n',feature('numcores'));end
try
    [~,os]=system('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption + '' | '' + (Get-CimInstance Win32_OperatingSystem).Version"');fprintf(fid,'OS: %s\n',strtrim(os));
    [~,cpu]=system('powershell -NoProfile -Command "(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name)"');fprintf(fid,'CPU: %s\n',strtrim(cpu));
    [~,ram]=system('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,2)"');fprintf(fid,'RAM_GB: %s\n',strtrim(ram));
catch
end
try,v=ver;for i=1:numel(v),fprintf(fid,'Toolbox: %s | %s\n',v(i).Name,v(i).Version);end,end
fclose(fid);fprintf('Environment captured: %s\n',out);
end
