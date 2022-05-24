#! /bin/bash

set -e

make_flag=''
imports_flag=''

while getopts 'm:i:' flag; do
  case "${flag}" in
    m) make_flag="${OPTARG}" ;;
    i) imports_flag="${OPTARG}" ;;
  esac
done

importfailure=0
makefailure=0

ignore=(
  "^open-cluster-management\.io\/addon-framework"
  "^open-cluster-management\.io\/api"
  "^open-cluster-management\.io\/multicloud-operators-channel"
)

parse_imports(){
  echo "Scanning dependencies..."

  gh_ocm='^github\.com\/open-cluster-management'
  ocm='^open-cluster-management\.io'
  replaced='.*\=>.github\.com\/stolostron'

  i=1
  replaces=0
  while read line; do
    # skip first line, this is the repo we are running the script from
    test $i -eq 1 && ((i=i+1)) && continue

    # skip imports in ignore list
    skip=0
    for idx in ${!ignore[@]};
    do
      ignore_str=${ignore[$idx]}
      if [[ ${line} =~ $ignore_str ]]; then
        skip=1
      fi
    done

    if [[ $skip -eq 1 ]]; then
      continue
    fi

    # find ocm dependencies
    if [[ ${line} =~ $gh_ocm || ${line} =~ $ocm ]]; then
      if ! [[ ${line} =~ $replaced ]]; then
        echo ${line}
        ((replaces++))
      fi
    fi
  done
  if [[ $replaces > 0 ]]; then
    echo "ERROR: ${replaces} OCM imports need to be replaced with Stolostron imports"
    importfailure=1
  else
    echo 'All imports in this repo have been updated to Stolostron!'
  fi
}

parse_make(){
  echo "Scanning Makefile..."

  ocm_url='.*https://raw.githubusercontent.com/open-cluster-management'

  replaces=0
  while read line; do
    # find ocm dependencies
    if [[ ${line} =~ $ocm_url ]]; then
      echo ${line}
      ((replaces++))
    fi
  done
  if [[ $replaces > 0 ]]; then
    echo "ERROR: ${replaces} OCM URLs in Makefile need to be replaced with Stolostron ones"
    makefailure=1
  else
    echo "All URLs in the Makefile have been updated to Stolostron!"
  fi
}

parse_make < <(${make_flag})
parse_imports < <(${imports_flag})

if [[ $importfailure -eq 1 || $makefailure -eq 1 ]]; then
  exit 1
fi
