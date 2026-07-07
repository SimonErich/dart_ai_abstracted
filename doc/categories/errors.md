# Errors

Every failure arrives as an AiException. Subclasses name the failure mode: bad
credentials, rate limiting, an invalid request, a transient network or server
fault, a malformed response, or a timed-out job. Catch the root type to handle
any failure, or a specific subclass to react to one.
