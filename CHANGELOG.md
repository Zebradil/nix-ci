# Changelog

## [1.1.0](https://github.com/Zebradil/nix-ci/compare/v1.0.2...v1.1.0) (2026-09-03)


### Features

* surface diff build failures in the PR body ([c89471b](https://github.com/Zebradil/nix-ci/commit/c89471b47f4dc5e257ac1465ff585ae83b53ad92))

## [1.0.2](https://github.com/Zebradil/nix-ci/compare/v1.0.1...v1.0.2) (2026-09-01)


### Fixes

* push exactly the closure the build reports ([d0a1237](https://github.com/Zebradil/nix-ci/commit/d0a12374fa5f60f953c542fd0a2f4849eff6e997))


### Documentation

* describe paths-file as the pushed set ([cae03ac](https://github.com/Zebradil/nix-ci/commit/cae03ac90efaa4d00a72e7de7d7f31d49cdde66e))


### Refactoring

* keep cache credentials out of the step that no longer uploads ([0afa3ab](https://github.com/Zebradil/nix-ci/commit/0afa3ab54229436fa6aebc631edb089424deaccc))

## [1.0.1](https://github.com/Zebradil/nix-ci/compare/v1.0.0...v1.0.1) (2026-09-01)


### Fixes

* drop bash 4 constructs so the actions run on macOS runners ([1152b08](https://github.com/Zebradil/nix-ci/commit/1152b08b6a5ad0a94ad1a7a70fef9e863f79005e))
* use a redirect instead of xargs -a for the cache push ([e8ada2a](https://github.com/Zebradil/nix-ci/commit/e8ada2a0c8966c4528a648b9e57c9651be211e6d))


### Documentation

* keep the quickstart examples on the current release ([aa30d54](https://github.com/Zebradil/nix-ci/commit/aa30d54e2a9ffcc851c33e763b04446dbc2fd102))

## [1.0.0](https://github.com/Zebradil/nix-ci/compare/v0.1.0...v1.0.0) (2026-08-31)


### ⚠ BREAKING CHANGES

* pin exact versions instead of a floating major tag

### Features

* pin exact versions instead of a floating major tag ([da9935e](https://github.com/Zebradil/nix-ci/commit/da9935e44648bb3792ee4590ddf12c56a7a1b06b))


### Fixes

* **release:** point the major tag at the commit, not the tag object ([d8fb376](https://github.com/Zebradil/nix-ci/commit/d8fb3763ed8dd917273d6c6e4674a5477fbc7bfa))
