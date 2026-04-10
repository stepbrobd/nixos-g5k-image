
# nixos-g5k-imag - generate NixOS image for Grid'5000 (WIP)

**This project is under development/refactoring (contact developer if you want to use it)**

This project help to generate a [NixOS](https://nixos.org) system image deployable on [Grid'5000](https://www.grid5000.fr) testbed platform. It uses the [nixos-configurators](https://github.com/nix-community/nixos-generators) tool.

## Installation
Just clone the repository
```console
$ git clone git@github.com:oar-team/nixos-g5k-image.git
```


## By using nix-datamove machine as remote builder (⚠️Experimental⚠️)

### Requirements
- You need to ask an NXC team member to give you access to the builder
- ⚠️ For building step you should be on Grenoble site. Building from other sites has not been tested.
- Install `setup-remote-nix.sh` on Grenoble site:
```bash
curl -L http://public.grenoble.grid5000.fr/~orichard/scripts/setup-remote-nix.sh  -o $HOME/.local/bin/setup-remote-nix.sh
chmod 755 $HOME/.local/bin/setup-remote-nix.sh
```
This script is used on a node to mount the store of nix-datamove.

- Install just, it's a task runner used to help to run some following steps
```bash
mkdir -p ~/.local/bin
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
```

###  Build image to deploy with Kadeploy
```bash
# reserve one node
oarsub -I
# mount /nix/store of nix-datamove machine
setup-remote-nix.sh
# go to directory
cd nixos-g5k-image
# update user.nix with user info
just generate-user-nix # or just u
# build image
just build # or just b
# get generated files from nix-datamove
just get-g5k-image-all # or just g

### Deploy Kadeploy image on nodes
```bash
# On frontend
cd nixos-g5k-image
oarsub -l walltime=2:0 -t deploy -I
# deploy 
just kadeploy # or just k
# ssh to node 
ssh ssh $(head -n 1 $OAR_NODEFILE)
# Becareful check you $PATH it's mixed with /home/$USER/.bashrc 
echo $PATH
```

NOTE: In the flake.nix kapack is added as overlay, to use its packages to be accessible who also need to list then in flake.nix (see environment.systemPackages), and not in configuration.nix .
