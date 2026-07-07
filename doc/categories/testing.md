# Testing

Each capability has an in-memory fake that returns fixed bytes without a network
call or an API key. Inject a fake where your code expects a capability, and you
can test the surrounding logic offline and deterministically.
