# tofu-modules

OpenTofu modules packaged as a monorepo with independent per-module versioning.

## Modules

Each top-level directory with a `versions.tf` is a versioned module. Current modules:

| Module | Description |
|--------|-------------|
| `scaleway-database` | Managed PostgreSQL (RDB) with secrets |
| `scaleway-kubernetes` | Kapsule cluster with Flux bootstrap |
| `scaleway-opensearch` | Managed OpenSearch deployment |
| `scaleway-network` | VPC and private network |
| `scaleway-transactional-email` | Transactional email (TEM) domain |

## Prerequisites

- [OpenTofu](https://opentofu.org/) (`tofu` on your `PATH`)
- [TFLint](https://github.com/terraform-linters/tflint)
- [terraform-docs](https://github.com/terraform-docs/terraform-docs)

Optional: [asdf](https://asdf-vm.com/) or [mise](https://mise.jdx.dev/) with `.tool-versions` for a pinned OpenTofu version.

## Development

List modules:

```bash
make list-modules
```

Build a single module (format, lint, docs, test, validate):

```bash
make -C scaleway-database build
```

Build all modules:

```bash
make build
```

## Releases

Modules are versioned independently. Tags follow `{module-name}-v{semver}` (for example `scaleway-database-v4.0.1`).

On merge to `main`, changed modules are released automatically via [semantic-release](https://semantic-release.gitbook.io/) using [Conventional Commits](https://www.conventionalcommits.org/) on pull request titles.

Prefer one module per pull request to avoid unintended version bumps.

### Test releases locally

Requires Docker:

```bash
./scripts/test-semantic-release.sh scaleway-kubernetes
./scripts/test-semantic-release.sh scaleway-kubernetes --simulate-main
```

The second command simulates a post-merge run on `main` using the current branch's release config and module `package.json`. Without `GITHUB_TOKEN`, dry-run may stop at git push verification; that still validates `extends`, `package.json`, and dependency installation.

## Consumption with Terragrunt

```hcl
terraform {
  source = "github.com/grrywlsn/tofu-modules.git//scaleway-kubernetes?ref=scaleway-kubernetes-v5.1.2"
}
```

Use a subdirectory path (`//module-name`) and a module-specific tag for the `ref`.
