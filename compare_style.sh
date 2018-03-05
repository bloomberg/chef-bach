#!/bin/bash

###########################################
# Script to compare style check differences
# between branches of code to make sure we
# are cleaning up and not regressing code
###########################################

########################################
# Function to gather master style output
# arguments: file path to write rake sytle output
# post-condition: the file path has rake style output
# returns: 1 on error
function gather_master_style {
  local my_branch=$(git branch | grep '^* ' | sed 's/^* //')
  if [[ -z $1 ]]; then
    echo -e 'gather_master_style:\tNeeds a filename to write rake style report' \
            'got nothing' > /dev/stderr
    return 1
  fi
  if [[ -z ${my_branch:=${TRAVIS_BRANCH}} ]]; then
    echo -e 'gather_master_style:\tFailed to get a current Git branch!' \
      > /dev/stderr
    return 1
  fi
  # since we are switching branches make sure to stash any local changes
  local git_message='compare_style.sh:gather_master_style()'
  if [[ -n $(git status -s) ]]; then
    export GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL:=compare_style.sh@example.com}
    export GIT_AUTHOR_NAME=${GIT_AUTHOR_NAME:=compare_style.sh script}
    echo 'Stashing local changes to checkout master'
    git stash save -a "${git_message}" >/dev/null 2>&1
  fi
  git remote add bloomberg https://github.com/bloomberg/chef-bach \
    >/dev/null 2>&1
  git fetch bloomberg master >/dev/null 2>&1
  git checkout bloomberg/master >/dev/null 2>&1
  if [[ $(git branch | grep '^* ' | sed 's/^* //') != \
        '(HEAD detached at bloomberg/master)' ]]; then
    echo -e 'gather_master_style:\tFailed to pull Bloomberg master' \
      > /dev/stderr
    return 1
  fi
  rake style >$1 2>&1 || true
  git checkout ${my_branch} >/dev/null 2>&1
  # re-apply any changes if we stashed changes
  if (($(git stash list --author=${GIT_AUTHOR_EMAIl} --grep=${git_mssage} | wc -l) == 1)); then
    echo 'Restoring local changes'
    git stash pop >/dev/null 2>&1
  fi
}

####################################################
# Function to parse FoodCritic Rake output to return
# the number of offenses
# arguments: file path with rake sytle output
#            (or will wait for standard-in to close)
# output: the integer number of offenses
function gather_chef_style_offenses {
  egrep '^FC[0-9]*:' $1 | wc -l
}


#################################################
# Function to parse RuboCop Rake output to return
# the number of offenses
# arguments: file path with rake sytle output
#            (or will wait for standard-in to close)
# output: the integer number of offenses
function gather_ruby_style_offenses {
  sed -n 's/^[0-9]* files inspected, \([0-9]*\) offenses detected$/\1/p' $1
}

###############################################
# Function to compare rake style outputs to see
# if the number of offenses if more than master
# argument: file path with local rake sytle output
# output: admonishment or congratulations for the
#         code under validation
# returns: 0: if there are fewer or equal offenses
#          1: if there are more offenses
#          2: if there was an error
function compare_offenses {
  if [[ -z $1 || ! -e $1 ]]; then
    echo -e 'compare_offenses:\tNeeds a filename with a rake style report' \
            "got: $1" > /dev/stderr
    return 2
  fi
  local master_style_file="${REPORT_DIR}/master_style.txt"
  gather_master_style ${master_style_file} || return 2
  local master_ruby_offenses=$(gather_ruby_style_offenses ${master_style_file})
  local master_chef_offenses=$(gather_chef_style_offenses ${master_style_file})
  local my_ruby_offenses=$(gather_ruby_style_offenses $1)
  local my_chef_offenses=$(gather_chef_style_offenses $1)
  if [[ -z "$master_ruby_offenses" || -z "$my_ruby_offenses" ]]; then 
    echo -e 'compare_offenses:\tFailed to gather Ruby offenses:\n' \
            "\tmaster:\t${master_ruby_offenses}\n\tmine:\t${my_ruby_offenses}"\
            "\n\tMaster style file ${master_style_file}"
    return 2
  elif [[ -z "$master_chef_offenses" || -z "$my_chef_offenses" ]]; then 
    echo -e 'compare_offenses:\tFailed to gather Chef offenses:\n' \
            "\tmaster:\t${master_chef_offenses}\n\tmine:\t${my_chef_offenses}"
            "\n\tMaster style file ${master_style_file}"
    return 2
  fi
  echo '############################################################'
  echo -e "## Found my offenses are:" \
       "Ruby: ${my_ruby_offenses} Chef: ${my_chef_offenses}" \
       "\n## Master's offenses are:" \
       "Ruby: ${master_ruby_offenses} Chef: ${master_chef_offenses}"
  if (( ${master_ruby_offenses} < ${my_ruby_offenses} || \
        ${master_chef_offenses} < ${my_chef_offenses})); then
    echo '## Commit regressed style!'
    echo '############################################################'
    return 1
  elif (( ${master_ruby_offenses} == ${my_ruby_offenses} && \
        ${master_chef_offenses} == ${my_chef_offenses})); then
    echo '## Commit did not improve style!'
    echo '############################################################'
    return 0
  else
    echo '## Commit improved style!'
    echo '############################################################'
    return 0
  fi
}

function setup_report_dir {
  export REPORT_DIR=$(mktemp -d --suffix '_chef-bach_build_out')
  echo "Using REPORT_DIR: ${REPORT_DIR}" >/dev/stderr
}

# only execute functions if being run and not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  setup_report_dir
  echo "Running rake style"
  rake style > "${REPORT_DIR}/style_output" 2>&1 || \
    echo "Swallowing -- guaranteed -- style failure"
  echo "Comparing offenses"
  compare_offenses "${REPORT_DIR}/style_output"
fi
