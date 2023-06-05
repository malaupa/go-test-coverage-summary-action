#!/usr/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/blob/$GITHUB_SHA"
SUMMARY_FILE=summary.md

if [[ -f "$GITHUB_WORKSPACE/$TEST_RESULT_LOG" ]] ; then
  echo "process test results"
  awk -f $SCRIPT_DIR/test_summary.awk -v workspace="$GITHUB_WORKSPACE" -v baseUrl="$BASE_URL" $GITHUB_WORKSPACE/$TEST_RESULT_LOG >> $SUMMARY_FILE
fi

if [[ -f "$GITHUB_WORKSPACE/$COVERAGE_PROFILE" ]] ; then
  echo "process coverage profile"
  PACKAGE=$(awk '$1 ~ /module/ { print $2 }' $GITHUB_WORKSPACE/go.mod)
  awk -f $SCRIPT_DIR/coverage_summary.awk -v package="$PACKAGE" -v baseUrl="$BASE_URL" $GITHUB_WORKSPACE/$COVERAGE_PROFILE >> $SUMMARY_FILE
fi

if [[ "$WITH_ARCHIVE" == "true" && -f "$GITHUB_WORKSPACE/$COVERAGE_PROFILE" ]] ; then
  echo "generate html report"
  go tool cover -html $GITHUB_WORKSPACE/$COVERAGE_PROFILE -o coverage.html
fi

SUMMARY="$(cat $SUMMARY_FILE)"
if [[ -f "$SUMMARY_FILE" && "$SUMMARY" != "" ]] ; then
  echo "attach job summary"
  echo "$SUMMARY" >> $GITHUB_STEP_SUMMARY

  if [[ "$PULL_REQUEST_NODE_ID" != "" ]] ; then
    echo "fetch comments"
    COMMENT_BODY=$(printf '%s\n%s\n' "$SUMMARY" "<!-- go-test-coverage-summary -->")
    COMMENTS="$(gh api graphql -F subjectId=$PULL_REQUEST_NODE_ID -f query='
      query($subjectId: ID!) {
        node(id: $subjectId) {
          ... on PullRequest {
            comments(first: 100) {
              nodes {
                id
                isMinimized
                body
              }
            }
          }
        }
      }
    ' --jq '.data.node.comments.nodes | map(select((.body | contains("<!-- go-test-coverage-summary -->")) and .isMinimized == false)) | map(.id)[]')"

    if [[ -n "$COMMENTS" ]]; then
      echo "update comment"
      for val in $COMMENTS; do
        gh api graphql -X POST -F id=$val -F body="$COMMENT_BODY" -f query='
          mutation UpdateComment($id: ID!, $body: String!) {
            updateIssueComment(input: {id: $id, body: $body}) {
              clientMutationId
            }
          }
        '
      done
    else
      echo "add comment"
      gh api graphql -X POST -F subjectId=$PULL_REQUEST_NODE_ID -F body="$COMMENT_BODY" -f query='
        mutation AddComment($subjectId: ID!, $body: String!) {
          addComment(input: {subjectId: $subjectId, body: $body}) {
            clientMutationId
          }
        }
      ' || true
    fi
  fi
fi