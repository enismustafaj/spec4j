## About

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-spec4j-blue?logo=github)](https://github.com/marketplace/actions/spec4j)

spec4j is a GitHub Action that turns a [TypeSpec](https://typespec.io/) API contract into a versioned Java library: it compiles the `.tsp` file to OpenAPI, generates Spring Boot REST interfaces and DTOs from it, packages them as a Maven jar, and deploys that jar to a Maven registry.

The idea: define an API's shape once, in one contract repo, and let every service that implements or calls it depend on the generated library instead of hand-writing (and drifting from) its own interfaces.

## Repo layout this action expects

A specs repo with one folder per API domain, each holding a `main.tsp`:

```
your-specs-repo/
├── users/main.tsp
├── orders/main.tsp
└── .github/workflows/
    ├── validate.yaml   # compiles changed specs on PRs, publishes nothing
    └── publish.yaml    # calls this action on a release tag
```

See `examples/users` and `examples/departments` in this repo for sample `main.tsp` files, and `.github/workflows/create-lib.yaml` / `publish.yaml` for the reference workflows to copy into your repo.

## Usage

```yaml
# .github/workflows/publish.yaml
on:
  push:
    tags: ['*/v*']   # e.g. "users/v1.2.0"

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - id: release
        run: |
          echo "domain=${GITHUB_REF_NAME%%/*}" >> "$GITHUB_OUTPUT"
          echo "version=${GITHUB_REF_NAME#*/v}" >> "$GITHUB_OUTPUT"
      - uses: enismustafaj/spec4j@1.0.3
        with:
          spec-path: ${{ steps.release.outputs.domain }}/main.tsp
          version: ${{ steps.release.outputs.version }}
          registry-id: gitlab-maven
          registry-url: https://gitlab.com/api/v4/projects/<numeric-id>/packages/maven
          registry-token: ${{ secrets.GITLAB_TOKEN }}
```

> **For GitLab, use the numeric project ID in `registry-url`, not the `namespace%2Fproject` URL-encoded path.** Both work with plain `curl`, but Maven's HTTP client mishandles the encoded slash and GitLab rejects the resulting request with a 400. Find the numeric ID on the project's main page or **Settings → General**.

Cutting a release is then just a tag:

```
git tag users/v1.2.0
git push origin users/v1.2.0
```

That publishes `com.spec4j:users:1.2.0` (or whatever `group-id`/`artifact-id` you set) to the registry. There's no floating SNAPSHOT — a version only gets published when it's tagged, and `version` must be a plain `X.Y.Z` semver string.

### Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `spec-path` | yes | — | Path to the `.tsp` file to compile |
| `version` | yes | — | Version to publish, e.g. `1.2.0` |
| `registry-id` | yes | — | Maven `<server>` id (must match the registry's auth config) |
| `registry-url` | yes | — | Maven repository URL to deploy to |
| `registry-token` | yes | — | Registry auth token, sent as a `Private-Token` header |
| `group-id` | no | `com.spec4j` | Maven groupId for the generated package |
| `artifact-id` | no | spec's parent folder name | Maven artifactId |
| `java-version` | no | `21` | JDK version used to compile/deploy |

Under the hood the action installs the TypeSpec compiler, runs `tsp compile`, renders `template/pom-template.xml` with these inputs, and runs `mvn deploy` using the bundled `settings.xml` (which reads the token from the `registry-token` input).

## Local development

This repo includes a devcontainer spec (Node 22, Java 21, Maven) if you want to hack on the action itself without installing those locally.

## Potential Improvements
- Multi-language codegen targets (TypeScript/Python clients), not just Spring
- AsyncAPI spec support
- Breaking-change detection between spec versions

## Contribution
In case you would like to contribute, please raise an issue and a PR for that issue.
