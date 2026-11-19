function cfg=Paper1_V22_apply_sensitivity(cfg,row)
cfg.sensor.fov_full_deg=row.fov_full_deg;cfg.sensor.range=row.sensor_range;cfg.sensor.landmark_mode=string(row.landmark_mode);cfg.safety.margin=row.safety_margin;
end
