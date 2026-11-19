# Corpus generator
`generate_primary_corpus_v22.py` deterministically recreates the 15 calibration and 90 evaluation maps from fixed seeds and rebuilds the dedicated smoke-validation map. It uses only the Python standard library.

The 15 diagnostic maps are static historical anchors and are intentionally not regenerated here.

Do not regenerate any corpus after the experiment is frozen. The frozen JSON files and SHA-256 manifest are the authoritative experiment inputs.
