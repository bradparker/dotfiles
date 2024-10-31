# Dotfiles

Keeping it simple

## Setup

#### 0. (Optional) Run the [install](./install) script

```
$ ./install
```

This has the effect of running the commands outlined in the next three steps.

#### 1. Install [Nix](https://nixos.org/nix/)

```
$ sh <(curl https://nixos.org/nix/install) --daemon
```

#### 2. Apply the [Home Manager](https://github.com/rycee/home-manager) configuration

```
$ nix --extra-experimental-features nix-command --extra-experimental-features flakes run home-manager/release-24.05 -- switch --flake .
```

#### 3. Change shell to [Bash](https://www.gnu.org/software/bash/)

Set the Nix-installed Bash as the one for your user.

```
$ sudo bash -c "echo $(which bash) >> /etc/shells"
$ chsh -s $(which bash) $(whoami)
```

You'll need to log out then in again for this to take effect.

#### [Base16 Shell](https://github.com/chriskempson/base16-shell)

Set the color scheme.

```
$ base16_tomorrow
```

## Switching to a new config

```
$ ./switch
```

Which has the effect of running the following

```
$ home-manager switch --flake .
```

## Updating the Nixpkgs version

Run the script

```
$ ./update
```

Which has the effect of running the following

```
$ nix-shell --run "niv update"
```
