# GitHub setup and lab collaboration

**Artifact ID:** ATAC-BASH-DOC-006  
**Canonical repository:** `https://github.com/ManaStemLab/ManaStemLab`

The lab repository should be the single authoritative copy because the STAR Methods and Key Resources Table already point readers there. A local clone is a working copy of that same repository, not a competing repository. Do not maintain separate personal and lab repositories with independent histories.

## Current repository state

As checked on 2026-08-04, `ManaStemLab/ManaStemLab` is public and empty. Dominic's current connected permissions allow reading but not pushing. An organization owner must grant Dominic the **Write** role before he can make the initial push.

## Initial setup

1. Ask the ManaStemLab organization owner to grant Dominic **Write** access to `ManaStemLab/ManaStemLab`.
2. Configure Git locally and authenticate with GitHub using either GitHub CLI or an SSH key.
3. Clone the empty lab repository.

   ```bash
   git clone https://github.com/ManaStemLab/ManaStemLab.git
   cd ManaStemLab
   ```

4. Copy the contents of `ATACseq_Bash_Compendium/` into the repository root. Because the repository is presently dedicated to this code release and is empty, an extra nested compendium directory is unnecessary.
5. Copy the sample/config templates, but commit only portable metadata and example configuration.

   ```bash
   cp config/samples.example.tsv config/samples.tsv
   cp config/project_config.example.sh config/project_config.sh
   ```

   `config/project_config.sh` is ignored because it contains machine-specific paths. `config/samples.tsv` should be committed after replacing the examples with the paper samples and using portable relative FASTQ paths or documented GEO filenames.

6. Validate before committing.

   ```bash
   bash tests/validate_compendium.sh
   git status
   ```

7. Create the initial commit and push `main`.

   ```bash
   git add .
   git commit -m "Add reproducible ATAC-seq analysis compendium"
   git branch -M main
   git push -u origin main
   ```

For the first push to an empty repository, pushing `main` directly is reasonable. After that initial commit, use feature branches and pull requests.

## Routine lab workflow

Each lab member clones the same canonical repository once:

```bash
git clone https://github.com/ManaStemLab/ManaStemLab.git
cd ManaStemLab
```

Before starting work:

```bash
git switch main
git pull --ff-only
git switch -c initials/short-change-description
```

After editing and validating:

```bash
git add path/to/changed/files
git commit -m "Describe the scientific or reproducibility change"
git push -u origin initials/short-change-description
```

Open a pull request into `main`, have at least one lab member review it, then merge. This preserves who changed what, why it changed, and which version supported each manuscript revision.

## How readers and the lab should reference the code

Use increasingly precise references depending on purpose:

- **General repository:** `https://github.com/ManaStemLab/ManaStemLab`
- **Manuscript-stable version:** a GitHub Release/tag such as `v1.0.0`
- **Exact computational state:** the full Git commit SHA used for the submitted analysis
- **Individual file:** a permanent GitHub link pinned to that tag or commit, not a moving `main` link

Create a GitHub Release at submission and attach the packaged compendium. Releases are based on Git tags, so they give the paper a stable version even as future corrections are merged.

Add a root `CITATION.cff` when the paper title, complete author order, journal, DOI, and repository release are final. GitHub uses this file to display a **Cite this repository** control.

## Personal portfolio visibility

Dominic does not need a second personal repository for portfolio credit. Commits and pull requests authored with an email linked to his GitHub account remain attributable to his profile even when the lab organization owns the repository. He can also pin or link the public lab repository from his profile README, CV, and portfolio.

If Write access cannot be granted, the clean fallback is for Dominic to prepare the complete local Git repository and have a ManaStemLab owner perform the initial push. After the repository has a first commit, a fork-and-pull-request workflow can be used if direct Write access remains unavailable.

## Official GitHub references

- [Adding locally hosted code to GitHub](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github)
- [Repository roles for an organization](https://docs.github.com/organizations/managing-user-access-to-your-organizations-repositories/repository-roles-for-an-organization)
- [Cloning a repository](https://docs.github.com/articles/cloning-a-repository)
- [Managing releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
- [About CITATION files](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-citation-files)
