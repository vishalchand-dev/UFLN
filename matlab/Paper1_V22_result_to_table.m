function T=Paper1_V22_result_to_table(r,phase,recordType,rep)
r.phase=string(phase);r.record_type=string(recordType);r.rep=rep;
T=struct2table(orderfields(r));
end
