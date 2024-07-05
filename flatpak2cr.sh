#! /bin/bash

set -e

for f
do
   d=$(cd $(dirname $f); pwd)
   id=$(yq -e '.flatpak.id' $f)
   name=$(yq -e '.flatpak.packages[0]' $f)
   pkgs=$(yq -e '.flatpak.packages' $f)
   arches=$(yq -e '.platforms.only[]' $f 2>/dev/null || true)

   cat > ${name}.yaml <<_EOF
document: feedback-pipeline-workload
version: 1
data:
  name: ${name}
  description: Fedora ${id} flatpak
  maintainer: flatpak-sig
  labels:
    - flatpak
_EOF

  if [ -n "$arches" ]; then
    yq -I 2 -i '.data.packages = []' ${name}.yaml
    for arch in $arches; do
       PACKAGES="$pkgs" yq -I 2 -i ".data.arch_packages.${arch} |= env(PACKAGES)" ${name}.yaml
    done
  else
    PACKAGES="$pkgs" yq -I 2 -i '.data.packages |= env(PACKAGES)' ${name}.yaml
  fi
done
