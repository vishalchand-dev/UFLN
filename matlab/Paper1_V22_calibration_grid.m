function G=Paper1_V22_calibration_grid()
G=struct();
G.ACO={struct('q',0.35,'sigma_frac',0.20),struct('q',0.35,'sigma_frac',0.30),struct('q',0.55,'sigma_frac',0.20),struct('q',0.55,'sigma_frac',0.30)};
G.BA={struct('loudness',0.75,'pulse',0.35),struct('loudness',0.75,'pulse',0.55),struct('loudness',0.90,'pulse',0.35),struct('loudness',0.90,'pulse',0.55)};
G.FA={struct('gamma',0.5,'alpha0',0.15),struct('gamma',0.5,'alpha0',0.25),struct('gamma',1.0,'alpha0',0.15),struct('gamma',1.0,'alpha0',0.25)};
G.SAFA={struct('gamma',0.5,'drift_frac',0.10),struct('gamma',0.5,'drift_frac',0.20),struct('gamma',1.0,'drift_frac',0.10),struct('gamma',1.0,'drift_frac',0.20)};
G.RRT={struct('step',0.60,'goal_bias',0.10),struct('step',0.60,'goal_bias',0.20),struct('step',0.90,'goal_bias',0.10),struct('step',0.90,'goal_bias',0.20)};
G.DVWP={struct('k_rep',0.5,'d0',4.0),struct('k_rep',0.5,'d0',6.0),struct('k_rep',0.9,'d0',4.0),struct('k_rep',0.9,'d0',6.0)};
end
