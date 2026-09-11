# Bump Version Action

[![Marketplace](https://img.shields.io/badge/Marketplace-Bump_Version_Action-2088FF.svg?style=flat&logo=githubactions&logoColor=white)](https://github.com/marketplace/actions/bump-version-action)
[![Release](https://img.shields.io/github/v/release/conjikidow/bump-version-action?style=flat&logo=github&logoColor=white&label=release)](https://github.com/conjikidow/bump-version-action/releases/latest)
[![License](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg?style=flat)](#license)
[![prek](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/j178/prek/master/docs/assets/badge-v0.json)](https://github.com/j178/prek)
[![CI](https://github.com/conjikidow/bump-version-action/actions/workflows/ci.yaml/badge.svg)](https://github.com/conjikidow/bump-version-action/actions/workflows/ci.yaml)

A GitHub Action to bump versions based on pull request (PR) labels.

This action follows the principles of [semantic versioning](https://semver.org),
incrementing the version number based on the labels applied to the PR.

## Features

- Automatically determines the version bump type based on PR labels.
- Supports manual workflow dispatch with an explicitly selected bump type.
- Uses [bump-my-version](https://github.com/callowayproject/bump-my-version)
  to increment the version according to semantic versioning.
- Creates a new branch and a PR for the version bump.
- Generates a corresponding Git tag once the version bump PR is merged.
- Optionally creates a GitHub Release for the new tag.

## Usage

### Workflow Example

Below are example workflows you can add to your repository to automatically bump the version when a PR is merged.
You can save them in a file such as `.github/workflows/bump-version.yaml`.

Make sure your workflow includes the following:

- The `on: pull_request: types: [closed]` trigger to run the workflow whenever a PR is closed.
- The `permissions:` section to allow the workflow to update repository contents and PRs.
- The job-level `if` condition to skip PRs that are closed without being merged.

#### Basic Example

```yaml
name: Bump Version

on:
  pull_request:
    types: [closed]

permissions: {}

jobs:
  bump-version:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - name: Bump Version
        uses: conjikidow/bump-version-action@v4.0.2
        with:
          label-major: 'major update'
          label-minor: 'minor update'
          label-patch: 'patch update'
          labels-to-add: 'automated,version-bump'
          create-release: 'true'
```

The examples reference actions by tag for readability.
For production workflows, consider pinning each action to a full-length commit SHA,
as [GitHub recommends](https://docs.github.com/en/actions/reference/security/secure-use#using-third-party-actions).
Releases of this action are immutable, so its full version tags (`vX.Y.Z`) are already locked to a single commit.

#### Example with Manual Dispatch

You can also use this action with manual workflow dispatch.
The following example adds a manual trigger that lets you choose the bump type when starting the workflow.

```yaml
name: Bump Version

on:
  pull_request:
    types: [closed]
  workflow_dispatch:
    inputs:
      bump_type:
        description: 'Version bump type'
        required: true
        type: choice
        options:
          - major
          - minor
          - patch

permissions: {}

jobs:
  bump-version:
    if: github.event_name == 'workflow_dispatch' || github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - name: Bump Version
        uses: conjikidow/bump-version-action@v4.0.2
        with:
          label-major: 'major update'
          label-minor: 'minor update'
          label-patch: 'patch update'
          manual-bump-type: ${{ inputs.bump_type }}
          labels-to-add: 'automated,version-bump'
          create-release: 'true'
```

#### Example with External Release Tools

You can also integrate this action with external tools or actions by using the outputs provided.
The following example uses [`softprops/action-gh-release`](https://github.com/softprops/action-gh-release)
to create a GitHub Release when the version has actually been bumped:

```yaml
name: Bump Version with External Release

on:
  pull_request:
    types: [closed]

permissions: {}

jobs:
  bump-version:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - name: Bump Version
        id: bump-version
        uses: conjikidow/bump-version-action@v4.0.2

      # This step is just a placeholder. You can replace it with your own script or external tools.
      - name: Create Release Notes
        if: steps.bump-version.outputs.version-bumped == 'true'
        run: |
            cat <<EOF > custom-release-notes.md
            ## What's Changed
            ...
            EOF

      - name: Create GitHub Release
        if: steps.bump-version.outputs.version-bumped == 'true'
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v${{ steps.bump-version.outputs.new-version }}
          body_path: custom-release-notes.md
```

### Permissions

The token passed to `github-token` needs `contents: write` to push the version bump branch and the tag,
and `pull-requests: write` to open the version bump pull request.

The default `${{ github.token }}` carries whatever the workflow grants it,
so grant those scopes in the job, as the examples above do.
`GITHUB_TOKEN` also needs the repository itself to allow it to open pull requests:

1. Go to the **Settings** tab of your repository.
2. On the left-hand menu, select **Actions/General**.
3. Under the **Workflow permissions** section, enable **`Allow GitHub Actions to create and approve pull requests`**.
4. Save the changes.

Neither the `permissions:` block nor that setting reaches a token you pass yourself.
A GitHub App installation token needs the same access granted to the app itself.

### Inputs

| Name                         | Description                                                                     | Required | Default               |
| ---------------------------- | ------------------------------------------------------------------------------- | -------- | --------------------- |
| `github-token`               | Token used to authenticate with GitHub.                                         | No       | `${{ github.token }}` |
| `version-of-bump-my-version` | Version of `bump-my-version` to use.                                            | No       | `'latest'`            |
| `label-major`                | Label that triggers a major version bump.                                       | No       | `'major'`             |
| `label-minor`                | Label that triggers a minor version bump.                                       | No       | `'minor'`             |
| `label-patch`                | Label that triggers a patch version bump.                                       | No       | `'patch'`             |
| `manual-bump-type`           | Bump type used for manual workflow dispatch runs: `major`, `minor`, or `patch`. | No       | `''`                  |
| `branch-prefix`              | Prefix of the version bump branch name.                                         | No       | `'workflow'`          |
| `labels-to-add`              | Labels to add to the version bump pull request, separated by commas.            | No       | `''`                  |
| `update-major-minor-tags`    | Whether to create or update the major (`vX`) and minor (`vX.Y`) tags.           | No       | `'false'`             |
| `create-release`             | Whether to create a GitHub Release for the new tag.                             | No       | `'false'`             |

- Set any of `label-major`, `label-minor`, or `label-patch` to an empty string (`''`) to disable that bump type.
- `manual-bump-type` is required for `workflow_dispatch` runs; the action fails when it is empty.
- Any labels specified in `labels-to-add` must already exist in your repository; the action fails if they do not.

### Outputs

| Name             | Description                                                                      |
| ---------------- | -------------------------------------------------------------------------------- |
| `version-bumped` | `true` when the version was bumped and a new tag was created; otherwise `false`. |
| `new-version`    | New version number (e.g. `1.2.4`). Empty when `version-bumped` is `false`.       |

### bump-my-version Configuration

To use this action, ensure that your project is configured to work with `bump-my-version`.
Below is an example `.bumpversion.toml` configuration file:

```toml
[tool.bumpversion]
current_version = "0.1.0"
commit = false
tag = false

[[tool.bumpversion.files]]
filename = "pyproject.toml"
search = 'version = "{current_version}"'
replace = 'version = "{new_version}"'

[[tool.bumpversion.files]]
filename = "CMakeLists.txt"
search = "VERSION {current_version}"
replace = "VERSION {new_version}"
```

> [!IMPORTANT]
> `commit` and `tag` should be set to `false` because this action handles these tasks automatically.

To generate a default configuration file, run the following command:

```console
uvx bump-my-version sample-config --no-prompt --destination .bumpversion.toml
```

For more details, refer to the official [bump-my-version documentation](https://callowayproject.github.io/bump-my-version/reference/configuration).

## How It Works

1. Checks the execution conditions
   - Runs for merged pull requests and manual workflow dispatches.
   - For other cases, the action skips execution.

2. Determines the bump type
   - For manual workflow dispatches, uses `manual-bump-type`.
   - Otherwise, extracts PR labels and determines whether a major, minor, or patch bump is required,
     in accordance with semantic versioning.
   - If no matching labels are found, the process stops.

3. Runs `bump-my-version` to bump the version
   - Uses `bump-my-version@latest` (or specified version).
   - Checks if the version was actually updated.

4. Creates a new branch and PR for the version bump
   - If the version is updated, a new branch (`${branch-prefix}/bump-version-from-X.Y.W-to-X.Y.Z`) is created.
   - A PR is automatically opened to merge the version bump.

5. After merging, creates a Git tag
   - The branch name is parsed to extract the new version number.
   - A Git tag (`vX.Y.Z`) is pushed to mark the new release.

6. Optionally creates a GitHub Release
   - If `create-release` is `true`, a GitHub Release is created for the new tag
     with automatically generated release notes.

### Tag Management

By default, this action only creates the full version tag (`vX.Y.Z`), which is never overwritten on subsequent releases.
This default is compatible with GitHub's [Immutable Releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)
setting and aligns with the recommendation to pin actions to specific versions
(ideally to a commit SHA) for supply chain security.

True immutability of tags and releases requires enabling **Enable release immutability**
in your repository's **Settings → General → Releases**.
This action's default behavior is designed to be compatible with that setting.

#### Enabling Major and Minor Tag Updates

If `update-major-minor-tags` is set to `'true'`, the action also creates or updates
the major (`vX`) and minor (`vX.Y`) tags based on the following rules:

- If `vX.Y` exists → update to `vX.Y.Z`.
- If `vX.Y` does not exist but a previous minor tag (`vX.Y` before the update) exists → create `vX.Y` and set it to `vX.Y.Z`.
- If `vX` exists → update to `vX.Y.Z`.
- If `vX` does not exist but a previous major tag (`vX` before the update) exists → create `vX` and set it to `vX.Y.Z`.
- If neither `vX` nor `vX.Y` exist, they are not created.

Examples:

- `v1.2.3 → v1.2.4`: Update `v1.2` and `v1` if they exist.
- `v1.2.3 → v1.3.0`: Create `v1.3` if `v1.2` exists, update `v1` if it exists.
- `v1.2.3 → v2.0.0`: Create `v2.0` if `v1.2` exists, create `v2` if `v1` exists.

> [!CAUTION]
> Updating major and minor tags requires force-pushing them,
> which is incompatible with the **Enable release immutability** repository setting.
> Enabling this option is discouraged for projects that prioritize supply chain security.

## License

Licensed under either of [MIT license](LICENSE-MIT) or [Apache License, Version 2.0](LICENSE-APACHE) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this software
by you, as defined in the Apache-2.0 license, shall be dually licensed as above,
without any additional terms or conditions.

## Contributing & Feedback

Contributions, bug reports, and feedback are always welcome!
Thank you for helping improve this project for everyone!
