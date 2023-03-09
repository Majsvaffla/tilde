#!/bin/sh

# A hook script to verify what is about to be pushed. Called by "git
# push" after it has checked the remote status, but before anything has been
# pushed. If this script exits with a non-zero status nothing will be pushed.
#
# This hook is called with the following parameters:
#
# $1 -- Name of the remote to which the push is being done
# $2 -- URL to which the push is being done
#
# If pushing without using a named remote those arguments will be equal.
#
# Information about the commits which are being pushed is supplied as lines to
# the standard input in the form:
#
#   <local ref> <local sha1> <remote ref> <remote sha1>
#

remote="$1"
url="$2"

z40=0000000000000000000000000000000000000000

while read local_ref local_sha remote_ref remote_sha
do
	if [ "$local_sha" = $z40 ]
	then
		# Handle delete
		:
	else
		if [ "$remote_sha" = $z40 ]
		then
			# New branch, examine all commits since origin/main
			range="$local_sha..origin/main"
		else
			# Update to existing branch, examine new commits
			range="$remote_sha..$local_sha"
		fi

		# Check for commit message starting with a rebase command
		commit_with_rebase_command=`git rev-list -n 1 -P --grep '^[a-z]+!' "$range"`
		if [ -n "$commit_with_rebase_command" ]
		then
			echo >&2 "Found not yet rebased history in commit $commit_with_rebase_command."
			exit 1
		fi
		# Check for commit message starting with WIP
		wip_commit=`git rev-list -n 1 -P --grep '^WIP' "$range"`
		if [ -n "$wip_commit" ]
		then
			echo >&2 "Found WIP in commit $wip_commit."
			exit 1
		fi
	fi
done

exit 0
