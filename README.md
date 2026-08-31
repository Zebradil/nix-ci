# nix-ci

Reusable GitHub Actions workflows and composite actions for Nix flake repositories.

Three jobs, done once:

- **Test flake outputs** — evaluate the flake, then build every declared output on a runner that can
  actually build it.
- **Update flake inputs** — run `nix flake update` on a schedule and open a PR that shows what the
  update really changes, as an [nvd] package diff, not just a lock-file hash bump.
- **Publish to a binary cache** — sign and push what was built, to any S3-compatible cache.

Nothing here assumes a particular cache, hosting provider, or secrets layout. Every site-specific
value arrives as an input.

## Quickstart

Pick the shape that matches your repository.

### A package or library flake

Everything under `checks.<system>` is built and published. Put your linters and tests in `checks`
and `nix flake check` reproduces CI exactly.

```yaml
# .github/workflows/ci.yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]

jobs:
  ci:
    uses: zebradil/nix-ci/.github/workflows/ci.yaml@v1
    with:
      discovery-types: checks
      runner-mapping: |
        x86_64-linux:ubuntu-latest
        aarch64-darwin:macos-26
      cache-url: ${{ vars.NIX_CACHE_URL }}
      cache-public-key: ${{ vars.NIX_CACHE_PUBLIC_KEY }}
      # Forks cannot read secrets, so do not ask them to push.
      push-to-cache: ${{ github.event.pull_request.head.repo.full_name == github.repository }}
    secrets:
      cache-signing-key: ${{ secrets.CACHE_SIGNING_KEY }}
      cache-s3-url: ${{ secrets.CACHE_S3_URL }}
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

Put the cache URL and public key in repository **variables**, not secrets: `vars` are readable by
fork pull requests and `secrets` are not, so a fork still gets cache reads.

### A devShell-only flake

Same as above with `discovery-types: devShells`. The shell's closure is what gets built and cached,
which is usually the point — contributors get a warm `nix develop`.

### A NixOS or nix-darwin configuration repository

System toplevels need `build-strategy: uncached-leaves`. A toplevel derivation compiles nothing; it
symlinks an already-substitutable runtime closure, so realizing one on a runner downloads gigabytes
and exhausts the disk while proving nothing. That strategy builds the genuinely uncached leaves
underneath instead — which is what proves the configuration compiles — and publishes the toplevel's
`.drv` recipe so the target host can realize it from the cache.

```yaml
jobs:
  ci:
    uses: zebradil/nix-ci/.github/workflows/ci.yaml@v1
    with:
      discovery-types: |
        nixosConfigurations
        darwinConfigurations
      build-strategy: uncached-leaves
      runner-mapping: |
        x86_64-linux:ubuntu-latest
        aarch64-linux:ubuntu-24.04-arm
        aarch64-darwin:macos-26
      push-to-cache: ${{ github.event.pull_request.head.repo.full_name == github.repository }}
    secrets:
      # ...as above
```

### Updating flake inputs

```yaml
# .github/workflows/update-pr.yaml
name: Update flake.lock
on:
  schedule:
    - cron: '0 0 * * *'
  workflow_dispatch:

jobs:
  update:
    uses: zebradil/nix-ci/.github/workflows/update-pr.yaml@v1
    with:
      auto-merge: true
      diff-targets: |
        checks.x86_64-linux.default
    secrets:
      app-id: ${{ secrets.CI_APP_ID }}
      app-private-key: ${{ secrets.CI_APP_PRIVATE_KEY }}
```

Configure a GitHub App and pass its credentials. A PR created with `GITHUB_TOKEN` does not fire
`pull_request` events, so your own CI never runs on it — which defeats auto-merge and leaves the
update unverified. The workflow still works without an App and tells you, in the PR body, that it
is degraded.

`diff-targets` are built before and after the update so the PR body can carry an [nvd] diff of what
actually changed. Targets whose system does not match the runner are skipped.

## Actions

The workflows above are wrappers. Call the actions directly when you need more control — in
particular, when you need to do something with the pushed closure that the wrapper cannot forward.

| Action | Purpose |
| --- | --- |
| `setup-nix` | Install Nix, add substituters, restore the two build caches, and register the signing key so builds sign themselves. |
| `discover` | Enumerate flake outputs into a build matrix. |
| `build` | Build one target and push it. Exposes `paths-file`. |
| `update-lock-pr` | Update `flake.lock`, diff, and open or update the PR. Exposes `paths-file`, `gen`, `branch`. |

Call `setup-nix` at job level before the others. None of these actions installs Nix itself, because
a composite action cannot invoke a sibling action in the same repository — a relative `uses:`
resolves against *your* workspace rather than this one ([actions/runner#1348]).

Chaining example, publishing a cache-specific manifest after the build:

```yaml
      - uses: zebradil/nix-ci/.github/actions/setup-nix@v1
        with:
          signing-key: ${{ secrets.CACHE_SIGNING_KEY }}
      - id: build
        uses: zebradil/nix-ci/.github/actions/build@v1
        with:
          attr: checks.x86_64-linux.myhost
          strategy: uncached-leaves
          cache-s3-url: ${{ secrets.CACHE_S3_URL }}
      - uses: some-org/some-cache/.github/actions/publish@v1
        with:
          paths-file: ${{ steps.build.outputs.paths-file }}
```

## Signing

`setup-nix` registers the signing key as nix.conf `secret-key-files`, so paths are signed as the
daemon builds them and every push is a plain copy. One consequence worth knowing: paths the runner
*substituted* rather than built keep only their upstream signature. If consumers of your cache also
trust `cache.nixos.org`, that is invisible. If they trust only your key, sign the closure yourself —
`setup-nix` exposes `signing-key-file` for exactly that.

## Versioning

Released with [release-please] from Conventional Commits. Pin `@v1`; the floating major tag moves to
each release, and Renovate will resolve it to an exact version and rewrite it to a commit SHA in
your repository. A `v1` workflow always calls `v1` actions — the major is the compatibility unit.

[nvd]: https://git.sr.ht/~khumba/nvd
[release-please]: https://github.com/googleapis/release-please
[actions/runner#1348]: https://github.com/actions/runner/issues/1348
