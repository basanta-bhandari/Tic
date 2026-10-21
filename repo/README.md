# Tic package repository

Glyph uses Pacman for dependency solving, signatures, upgrades, rollback via the
package cache, and file ownership. TAC supplies stable capability
names such as `file-manager-1`; it does not replace Pacman with a second package
database.

`build-meta.sh` turns every row in
`overlay/etc/glyph/capabilities.tsv` into a tiny Arch meta-package. Installing
`file-manager-1`, for example, installs its current provider (`nnn`). Provider
changes can therefore happen in a later repository revision without changing
the public capability name.

Build a local repository on Arch:

```sh
sudo pacman -S --needed base-devel pacman-contrib
./repo/build-meta.sh
```

Set `GLYPH_REPO_SIGNING_KEY` to a GPG key ID to sign the repository database.
Production publishing should sign every package as well, serve the directory
over HTTPS, retain old versions, and use a domain controlled by the project.
The example [`tic.repo.conf.example`](tic.repo.conf.example) Pacman stanza
deliberately has no server until that infrastructure exists. The source
repository is named **Tic**; `tac` is the command users run.
