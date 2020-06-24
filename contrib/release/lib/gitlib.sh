#!/bin/bash
#
# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################
# GIT-related constants and functions

###############################################################################
# CONSTANTS
###############################################################################
GHCURL="curl -s --fail --retry 10 -u ${GITHUB_TOKEN:-$FLAGS_github_token}:x-oauth-basic"
JCURL="curl -g -s --fail --retry 10"
CILIUM_GITHUB_API='https://api.github.com/repos/cilium/cilium'
CILIUM_GITHUB_RAW_ORG='https://raw.githubusercontent.com/cilium'

CILIUM_GITHUB_SEARCHAPI='https://api.github.com/search/issues?per_page=100&q=is:pr%20is:merged%20repo:cilium/cilium%20'
CILIUM_GITHUB_URL='https://github.com/cilium/cilium'
CILIUM_GITHUB_SSH='git@github.com:cilium/cilium.git'

# Regular expressions for bash regex matching
# 0=entire branch name
# 1=Major
# 2=Minor
# 3=.Patch
# 4=Patch
BRANCH_REGEX="master|release-([0-9]{1,})\.([0-9]{1,})(\.([0-9]{1,}))*$"
# release - 1=Major, 2=Minor, 3=Patch, 4=-(alpha|beta|rc), 5=rev
# dotzero - 1=Major, 2=Minor
# build - 1=build number, 2=sha1
declare -A VER_REGEX=([release]="v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[a-zA-Z0-9]+)*\.*(0|[1-9][0-9]*)?"
                      [dotzero]="v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.0$"
                      [build]="([0-9]{1,})\+([0-9a-f]{5,40})"
                     )

###############################################################################
# FUNCTIONS
###############################################################################

###############################################################################
# Looks up the list of releases on github and puts the last release per branch
# into a global branch-indexed dictionary LAST_RELEASE[$branch]
#
# USEFUL: LAST_TAG=$(git describe --abbrev=0 --tags)
gitlib::last_releases () {
  local release
  local branch_name
  local latest_branch
  declare -Ag LAST_RELEASE

  logecho -n "Setting last releases by branch: "
  for release in $($GHCURL $CILIUM_GITHUB_API/releases|\
                   jq -r '.[] | select(.draft==false) | .tag_name'); do
    # Alpha releases only on master branch
    if [[ $release =~ -alpha ]]; then
      LAST_RELEASE[master]=${LAST_RELEASE[master]:-$release}
    elif [[ $release =~ v([0-9]+\.[0-9]+)\.([0-9]+(-.+)?) ]]; then
      # Latest vx.x.0 release goes on both master and release branch.
      if [[ ${BASH_REMATCH[2]} == "0" ]]; then
        LAST_RELEASE[master]=${LAST_RELEASE[master]:-$release}
      fi
      branch_name=release-${BASH_REMATCH[1]}
      LAST_RELEASE[$branch_name]=${LAST_RELEASE[$branch_name]:-$release}
    fi
  done

  logecho -r "$OK"
}

###############################################################################
# What branch am I on?
# @optparam repo_dir - An alternative (to current working dir) git repo
# prints current branch name
# returns 1 if current working directory is not git repository
gitlib::current_branch () {
  local repo_dir=$1
  local -a git_args

  [[ -n "$repo_dir" ]] && git_args=("-C" "$repo_dir")

  if ! git ${git_args[*]} rev-parse --abbrev-ref HEAD 2>/dev/null; then
    (
    logecho
    logecho "Not a git repository!"
    logecho
    ) >&2
    return 1
  fi
}

###############################################################################
# Validates github token using the standard $GITHUB_TOKEN in your env
# returns 0 if token is valid
# returns 1 if token is invalid
gitlib::github_api_token () {
  logecho -n "Checking for a valid github API token: "
  if ! $GHCURL $CILIUM_GITHUB_API >/dev/null 2>&1; then
    logecho -r "$FAILED"
    logecho
    logecho "No valid github token found in environment or command-line!"
    logecho
    logecho "If you don't have a token yet, go get one at" \
            "https://github.com/settings/tokens/new"
    logecho "1. Fill in 'Token description': $PROG-token"
    logecho "2. Check the []repo box"
    logecho "3. Click the 'Generate token' button at the bottom of the page"
    logecho "4. Use your new token in one of two ways:"
    logecho "   * Set GITHUB_TOKEN in your environment"
    logecho "   * Specify your --github-token=<token> on the command line"
    common::exit 1
  fi
  logecho -r "$OK"
}
