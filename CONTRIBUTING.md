# Contributing to vaft-matlab

Thanks for helping. vaft-matlab is meant to stay a thin MATLAB-native
layer, so please read [docs/architecture.md](docs/architecture.md) first.

## Ground rules

- **Don't duplicate.** IMAS I/O, IDS definitions and serialization come
  from IMAS-MATLAB. Scientific algorithms come from Python VAFT. If you need
  something from either, open an issue to discuss how to reuse it.
- **No placeholders.** Add a new namespace (`+vaft/+plot`, ...) only
  together with a working implementation, tests and documentation.
- **Write MATLAB style:** `arguments` validation, name-value options,
  `handle` classes for resources, and error identifiers of the form
  `vaft:<Component>:<problem>`.
- Don't vendor third-party code or generated IDS definitions.

## Development setup

1. Install MATLAB R2024b or newer.
2. Optionally, for integration tests, install IMAS-MATLAB
   ([docs/installation.md](docs/installation.md)).
3. In MATLAB, from the repository root, run:

   ```matlab
   buildtool             % code checks + unit tests
   buildtool integration % needs IMAS-MATLAB on the path
   ```

## Tests

- `tests/unit/` must pass without IMAS or Python. Use the test double in
  `tests/support/FakeBackend.m` for Data Entry behavior.
- `tests/integration/` writes its own small HDF5 Data Entry into a
  temporary folder with IMAS-MATLAB. These tests are skipped when
  IMAS-MATLAB isn't available. Don't commit data files.
- Live HSDS or VEST database access isn't used in CI.

## CI

- **unit**: GitHub-hosted Ubuntu with MATLAB R2024b. Runs `buildtool check test`.
- **integration**: runs only on a self-hosted runner labelled
  `self-hosted, matlab, imas` that has MATLAB and IMAS-MATLAB installed.
  It's enabled by setting the repository variable `IMAS_RUNNER=true`, or
  run manually with *Run workflow*. The runner must have a MATLAB license,
  and `al_env.sh` must be sourced in its environment (for example in the
  runner's `.env` file or service definition).

## Versioning and changelog

- [Semantic Versioning](https://semver.org/). Before 1.0, minor versions
  may break the API.
- Update `CHANGELOG.md` under *Unreleased* in every pull request that
  changes behavior.
- Releases: bump `+vaft/version.m`, move the changelog entries under the
  new version, then tag `vX.Y.Z` on `main`.

## Pull requests

- Branch from `main` and keep each PR focused.
- `buildtool` must pass, with no code-analyzer warnings.
- Describe what you tested. For integration tests, include the
  `vaft.doctor` output.

## License

By contributing, you agree that your contributions are licensed under the
Apache License 2.0.
