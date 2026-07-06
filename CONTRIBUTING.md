# Contributing

Thanks for taking the time to help. New providers, bug fixes, and documentation
improvements are all welcome. This page covers the setup, the checks that need
to pass, and a few conventions.

## Setup

You need the Dart SDK (3.12 or newer). Then:

```sh
git clone https://github.com/SimonErich/dart_ai_abstracted.git
cd dart_ai_abstracted
dart pub get
```

Install the git hooks once. They check that commit messages follow the
convention below:

```sh
bash tool/install_hooks.sh
```

## The checks

Run these before you open a pull request. CI runs the same set.

```sh
dart format --set-exit-if-changed .      # formatting (page width 100)
dart analyze --fatal-infos --fatal-warnings
dart test
```

Everything public needs a doc comment; the analyzer enforces this. The test
suite runs offline. The live provider tests are tagged `generative` and are
excluded by default; run them only when you want to check real wire shapes, with
the relevant keys set:

```sh
RUN_INTEGRATION=1 GEMINI_API_KEY=... dart test --tags generative
```

Coverage stays high. To see it locally:

```sh
dart pub global activate coverage
dart test --coverage=coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

## Adding a provider

The steps are the same for any capability:

1. Create the client under `lib/src/providers/<vendor>/`. Implement the matching
   contract (`TextGenerator`, `ImageGenerator`, and so on). Take
   `credentials`, an optional `httpClient`, a `retryPolicy`, an `endpoint`
   override, and a `sleep` seam, so tests can inject them.
2. Use the shared transport helpers in `lib/src/transport/` (`postJson`,
   `getJson`, `getBytes`, `postForBytes`, `withRetry`, `pollUntil`) so retries,
   backoff, and error mapping match the rest of the package.
3. Map failures to the `AiException` subtypes. The transport helpers already do
   this for HTTP status codes; add an `AiResponseException` when the body is not
   the shape you expect.
4. Add the provider to `ProviderId` and wire it into `ProviderRegistry`.
5. Export the client from `lib/ai_abstracted.dart`.
6. Write tests with `package:http/testing` `MockClient` and a canned response.
   Pass `sleep: (_) async {}` so retries do not wait. Cover the happy path, an
   error status, and any polling.
7. Add a provider page under `doc/providers/` following the existing ones.

If you already wrote a provider for your own project, a pull request is the best
home for it. Others will want the same thing.

## Style

- One primary public type per file. Name files after what they hold.
- Keep the library free of `dart:io` and Flutter. It has to run everywhere.
- Documentation and prose use plain, direct language. No em-dashes.
- Constructors and fields take named parameters where it helps at the call site.

## Commits

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): summary
```

Common types are `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, and `ci`.
The scope is optional, for example `feat(providers): add Cohere text client`.
The commit hook checks the format.

## Pull requests

Keep a pull request to one logical change. Describe what changed and why. Make
sure the checks above pass. If you added a feature, add or update its
documentation in the same pull request.
