function trace=ufln_trace_struct(M,recordKey,plannerName,mapId,seed)
trace=struct();trace.record_key=string(recordKey);trace.planner=string(plannerName);trace.map_id=string(mapId);trace.seed=seed;
trace.columns={'time','x','y','theta','v','omega','active_landmark','visible_count','prop_x','prop_y','exec_x','exec_y','clearance','scan','fallback'};
trace.data=M;
end
