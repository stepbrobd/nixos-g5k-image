alias fmt := format

default:
    @just --list

# Format files: nix, README.md, justfile
[group('chore')]
format:
    nix fmt
