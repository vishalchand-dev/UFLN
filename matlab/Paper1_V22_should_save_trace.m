function tf=Paper1_V22_should_save_trace(result,recordType,cfg)
if recordType~="PATH",tf=false;return;end
if ~result.success,tf=true;return;end
if result.seed==0,tf=true;return;end
tf=(result.seed==cfg.experiment.trace_representative_seed);
end
