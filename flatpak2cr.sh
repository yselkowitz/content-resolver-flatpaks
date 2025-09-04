#! /bin/bash

set -e

for f
do
   d=$(cd $(dirname $f); pwd)
   id=$(yq -e '.flatpak.id' $f)
   pkgs=$(yq -e '.flatpak.packages' $f)
   arches=$(yq '.platforms.only[]' $f)
   build_runtime=$(yq '.flatpak | has("build-runtime")' $f)
   build_extension=$(yq '.flatpak | has("build-extension")' $f)
   component=$(yq '.flatpak.component' $f)
   runtime_id=$(yq '.flatpak.runtime' $f)
   runtime_name=$(yq '.flatpak.runtime-name' $f)
   label=

   if  [ "$build_runtime" = "true" ]; then
     name=${component}
     label=${name}
   elif [ "$build_extension" = "true" ]; then
     name=${component%-flatpak}
     case "${runtime_id}" in
       org.fedoraproject.Sdk) label=flatpak-sdk ;;
       *) label=flatpak-runtime ;;
     esac
   else
     name=$(yq -e '.flatpak.packages[0]' $f)
     case "${runtime_name}" in
       flatpak-runtime) label=flatpak-app ;;
       flatpak-sdk) label=flatpak-sdk-app ;;
       flatpak-kde5-runtime) label=flatpak-kde5-app ;;
       flatpak-kde5-sdk) label=flatpak-kde5-sdk-app ;;
       flatpak-kde6-runtime) label=flatpak-kde6-app ;;
       flatpak-kde6-sdk) label=flatpak-kde6-sdk-app ;;
       *) echo "ERROR: unknown runtime-name: ${runtime_name}"; exit 1 ;;
     esac
   fi

   cat > ${name}.yaml <<_EOF
document: feedback-pipeline-workload
version: 1
data:
  name: ${name}
  description: Fedora ${id} flatpak
  maintainer: flatpak-sig
  labels:
    - ${label}
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
