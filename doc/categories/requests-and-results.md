# Requests and results

Each medium has its own typed request that carries the prompt and the fields
that medium supports. Every capability answers with the same GenerationResult:
the raw bytes, their MIME type, the media kind, and metadata about the run. One
result shape covers all six mediums, so calling code reads the output the same
way everywhere.
