# Capabilities

Six single-method contracts, one per medium: text, image, video, speech, sound
effect, and music. Each contract describes what to generate, not how. You code
against the contract and swap the implementation, so a real provider client and
an in-memory fake are interchangeable at the call site.
