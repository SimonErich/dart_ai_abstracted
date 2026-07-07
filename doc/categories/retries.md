# Retries

The clients retry failed calls with exponential backoff driven by a RetryPolicy.
The policy sets how many attempts to make and how long to wait between them. A
small helper decides which HTTP status codes are worth retrying, so rate limits
and server faults back off while client errors fail fast.
