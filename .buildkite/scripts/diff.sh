#!/bin/bash
set -ueo pipefail

# Return file diff for 3 scenarios:
# 1. commit is at a different branch against <branch_name> - diff is against the branch off commit
# 2. commit is a merge to the <branch_name> - diff is the head branch of the merge against the branch off commit (wrt base branch)
# 3. commit is a sequential commit on the same barnch as <branch_name> - diff is against the previous commit
# Usage: ./diff.sh $BUILDKITE_COMMIT <branch_name>

COMMIT_HASH=$1

# <branch_name> -> buildkite default branch -> "V1.6"
BRANCH_TO_COMPARE=${2:-${BUILDKITE_PIPELINE_DEFAULT_BRANCH:-"master"}}

echo >&2 "Compare with $BRANCH_TO_COMPARE"

git fetch origin "$BRANCH_TO_COMPARE"

FETCH_HEAD_COMMIT=$(git rev-parse FETCH_HEAD)

if [[ $(git rev-list --no-walk --count --merges "${COMMIT_HASH}") -eq 1 ]]; then
    # is a merge commit
    DIFF_AGAINST_COMMIT=$(.buildkite/scripts/find-branch-point.sh "${COMMIT_HASH}^2" "${FETCH_HEAD_COMMIT}")
else
    DIFF_AGAINST_COMMIT=$(.buildkite/scripts/find-branch-point.sh "$COMMIT_HASH" "${FETCH_HEAD_COMMIT}")
fi

# when commit on the $BRANCH_TO_COMPARE, DIFF_AGAINST_COMMIT could be empty
echo >&2 "Running diff against: ${DIFF_AGAINST_COMMIT:="${COMMIT_HASH}~1"}"
git --no-pager diff --name-only "$DIFF_AGAINST_COMMIT" "$COMMIT_HASH"

