# nixos-g5k-image templates to generate NixOS images for Grid'5000 (WIP)

**This project is under development/refactoring (contact the developer if you
want to use it)**

This project helps generate [NixOS](https://nixos.org) system images deployable
on the [Grid'5000](https://www.grid5000.fr) testbed platform. These images are
also known as _environments_ in [Kameleon](https://github.com/oar-team/kameleon)
terminology.

# Template installation

**Important:** Images are provided as Nix flake templates, but as of 2026 Q1,
Nix is not natively installed on Grid'5000. User-level Nix installation has some
limitations, which restrict direct usage of Nix template initialization on
Grid'5000.

Two approaches are possible to use template:

1. Use an external machine with native Nix (e.g. your laptop) to get template
   then copy it on Grid'5000

```console
# Get template on external machine 
mkdir project && cd project
nix flake init --template "github:oar-team/nixos-g5k-image#user"
cd ..
# Copy to testbed, command may differ following your ssh config
scp -a project grenoble.g5k:
```

2. (**Preferred**) Clone this repository in Grid'5000 then copy the selected
   template:

```console
# On Grid'5000
git clone git@github.com:oar-team/nixos-g5k-image.git
mkdir project && cd project
cp -a ../nixos-g5k-image/templates/user"
git init .
git add *
```

## Available templates (image recipes)

- _minimal_: only root user, kadeploy will user's internal SSH public key
- _user_: after minimal adjusments, user's Grid'5000 account is added with $HOME
  access
- _kapack_: example with kapack packages and modules added with an overlay
- _nfs-store_: diskless image (nix store get from nfs server ) with user support
  (use kareboot3 for deployment)

## By using nix-datamove machine as remote builder (⚠️Experimental⚠️)

### Requirements

- You need to ask an NXC team member to give you access to the builder
- ⚠️ For building step you should be on Grenoble site. Building from other sites
  has not been tested.
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

### Build image to deploy with Kadeploy

```bash
# reserve one node
oarsub -I
# mount /nix/store of nix-datamove machine
setup-remote-nix.sh
# go to directory
cd nixos-g5k-image
# update user.nix with user info (only for user and kapack templates)
just generate-user-nix # or just u
# build image
just build # or just b
# get generated files from nix-datamove
just get-g5k-image-all # or just g
```

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

### Build and deploy diskless image (nfs-store) to deploy with Kareboot

#### Build

```bash
# reserve one node
oarsub -I
# mount /nix/store of nix-datamove machine
setup-remote-nix.sh
# go to directory
cd nfs-store
# update user.nix with user info (only for user and kapack templates)
just generate-user-nix # or just u
# build image
just remote-build # or just rb

# get generated kernel/initrd from nix-datamove
just get-g5k-nfs-store # or just g
```

#### Deploy

```bash
# On frontend
cd nfs-store

# Reserve one node, type destructive needed w/ the particular use of kadeploy 
oarsub -t deploy -t destructive -l nodes=1 -I # or just o

# deploy 
just kareboot # or just k

# ssh to node 
ssh ssh $(head -n 1 $OAR_NODEFILE)

# Becareful check you $PATH it's mixed with /home/$USER/.bashrc 
echo $PATH
```
