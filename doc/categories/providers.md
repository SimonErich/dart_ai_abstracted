# Providers

The concrete clients that talk to each provider's HTTP API and implement one or
more capabilities. The registry maps a ProviderId to the client for a given
capability, so you can pick the provider at runtime instead of naming a class in
your code.
