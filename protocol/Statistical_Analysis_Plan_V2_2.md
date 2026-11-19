# Statistical analysis plan V2.2

The primary independent experimental unit is the generated evaluation map, not the individual stochastic seed. Seeds characterize within-map stochastic variability.

Reliability will be analyzed at map level and with mixed/hierarchical models where appropriate. For stochastic planners, each map provides a success proportion over 30 seeds. Continuous quality metrics are summarized within planner-map before cross-map comparison. Difficulty is a pre-specified stratum.

Primary comparisons will report effect magnitudes and uncertainty, not only p-values. Candidate methods include paired bootstrap intervals across maps, mixed-effects logistic models for success, and hierarchical/paired models for continuous successful-run summaries. Multiplicity correction will be applied to declared post-hoc families.

Failure metrics are not silently converted into attractive short paths. Success/termination is analyzed first; successful-run quality is conditional and explicitly labelled.

Distance/reference ratio and control effort will be checked for redundancy before any multi-criteria summary. No universal composite score is required.
