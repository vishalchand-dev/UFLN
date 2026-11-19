function L = ufln_landmarks(map,cfg)
switch lower(string(cfg.sensor.landmark_mode))
    case "low", L=map.landmarks_low;
    case "high", L=map.landmarks_high;
    otherwise, L=map.landmarks_med;
end
end
