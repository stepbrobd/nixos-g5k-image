
alias b := build
alias u := generate-user-nix
alias g := get-g5k-image-all
alias k := kadeploy
default:
    @just --list

# Build vm
build JSON_FILE="result.json":
    nix --extra-experimental-features mounted-ssh-store --store mounted-ssh-ng://doozer@nix-datamove build .#g5k-image --no-link --json > {{ JSON_FILE }}

# Generate the user.nix file
generate-user-nix:
    #!/usr/bin/env bash
    echo '{
        name = "'$(id -nu)'";
        uid = '$(id -u)';
        id_rsa_pub = "'$(cat ~/.ssh/id_rsa.pub)'";
    }' > user.nix

# Get generated files from nix-datamove
get-g5k-image-all:
    #!/usr/bin/env bash
    nix_store_g5k_image_all=$(jq -r .[0].outputs.out result.json)
    if [ -d  ]; then
      echo "remove previous g5k-image-all"
      chmod -R 755 g5k-image-all
      rm -rf g5k-image-all
    fi
    scp -r doozer@nix-datamove:$nix_store_g5k_image_all g5k-image-all

# Launch Kadeploy command
kadeploy:
    kadeploy3 -a g5k-image-all/nixos-x86_64-linux.yaml
