# Changelog

## [3.2.1](https://github.com/Zebradil/nix-ci/compare/v3.2.0...v3.2.1) (2026-11-26)


### Fixes

* **build:** derive the uncached-leaves push from the build, not the store ([#39](https://github.com/Zebradil/nix-ci/issues/39)) ([cb780a9](https://github.com/Zebradil/nix-ci/commit/cb780a93ff8ef3da00513a5f8e9e9e68f0ba97c0))

## [3.2.0](https://github.com/Zebradil/nix-ci/compare/v3.1.0...v3.2.0) (2026-11-25)


### Features

* build in a runner-declared remote store and push to a kasha box ([#37](https://github.com/Zebradil/nix-ci/issues/37)) ([d8b1275](https://github.com/Zebradil/nix-ci/commit/d8b12752b691579cec6ac22b48c31dde032bf91b))

## [3.1.0](https://github.com/Zebradil/nix-ci/compare/v3.0.0...v3.1.0) (2026-11-16)


### Features

* **build:** summarize Nix downloads and builds in the job summary ([#31](https://github.com/Zebradil/nix-ci/issues/31)) ([bdba665](https://github.com/Zebradil/nix-ci/commit/bdba665e3fc837920f8c97194ac598dc8afda299))

## [3.0.0](https://github.com/Zebradil/nix-ci/compare/v2.0.2...v3.0.0) (2026-11-15)


### ⚠ BREAKING CHANGES

* install upstream Nix instead of Determinate Nix ([#28](https://github.com/Zebradil/nix-ci/issues/28))

### Features

* install upstream Nix instead of Determinate Nix ([#28](https://github.com/Zebradil/nix-ci/issues/28)) ([10f9cb5](https://github.com/Zebradil/nix-ci/commit/10f9cb5609ea9f27f02149a8383260fcb0d29fb5))

## [2.0.2](https://github.com/Zebradil/nix-ci/compare/v2.0.1...v2.0.2) (2026-10-18)


### Fixes

* keep Determinate Nix from logging in to FlakeHub on every nix step ([#23](https://github.com/Zebradil/nix-ci/issues/23)) ([7414ca9](https://github.com/Zebradil/nix-ci/commit/7414ca9d852da2410860eb6bb8fedcacc9e5c432))

## [2.0.1](https://github.com/Zebradil/nix-ci/compare/v2.0.0...v2.0.1) (2026-10-02)


### Fixes

* file pull request manifests under kasha's shared pr branch ([#19](https://github.com/Zebradil/nix-ci/issues/19)) ([35809ac](https://github.com/Zebradil/nix-ci/commit/35809ac2483476a2c8f4e3afc03aa7583f9f8c69))

## [2.0.0](https://github.com/Zebradil/nix-ci/compare/v1.3.0...v2.0.0) (2026-10-02)


### ⚠ BREAKING CHANGES

* publish a kasha manifest after every push ([#17](https://github.com/Zebradil/nix-ci/issues/17))

### Features

* publish a kasha manifest after every push ([#17](https://github.com/Zebradil/nix-ci/issues/17)) ([a436e75](https://github.com/Zebradil/nix-ci/commit/a436e75222368ad2e11c43660ce3b2d239880513))

## [1.3.0](https://github.com/Zebradil/nix-ci/compare/v1.2.0...v1.3.0) (2026-10-01)


### Features

* **setup-nix:** disable determinate-nix job summary ([17f4755](https://github.com/Zebradil/nix-ci/commit/17f475597eac92de381bf96d87befee3d012d7c6))

## [1.2.0](https://github.com/Zebradil/nix-ci/compare/v1.1.0...v1.2.0) (2026-10-01)


### Features

* **setup-nix:** trust the Zebradil cache centrally ([#14](https://github.com/Zebradil/nix-ci/issues/14)) ([3c9f67e](https://github.com/Zebradil/nix-ci/commit/3c9f67e59991fb8147ea9d97c30c39c9cd0e4d65))

## [1.1.0](https://github.com/Zebradil/nix-ci/compare/v1.0.2...v1.1.0) (2026-09-06)


### Features

* publish to the cache with zstd instead of xz ([#11](https://github.com/Zebradil/nix-ci/issues/11)) ([73bcb59](https://github.com/Zebradil/nix-ci/commit/73bcb598508fb9a3ef15a3759367c52347bd4e5f))
* surface diff build failures in the PR body ([c89471b](https://github.com/Zebradil/nix-ci/commit/c89471b47f4dc5e257ac1465ff585ae83b53ad92))


### Refactoring

* drop the flake source store cache ([#12](https://github.com/Zebradil/nix-ci/issues/12)) ([b00986d](https://github.com/Zebradil/nix-ci/commit/b00986d1695c7a7297bc8228d5d8af3b79851660))

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
