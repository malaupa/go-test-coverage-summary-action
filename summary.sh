#!/usr/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/blob/$GITHUB_SHA"
SUMMARY_FILE=summary.md
PROCESS_COVERAGE_REPORT=coverage.html

if [[ -f "$GITHUB_WORKSPACE/$TEST_RESULT_LOG" ]] ; then
  echo "process test results"
  awk -f $SCRIPT_DIR/test_summary.awk -v workspace="$GITHUB_WORKSPACE" -v baseUrl="$BASE_URL" $GITHUB_WORKSPACE/$TEST_RESULT_LOG >> $SUMMARY_FILE
  echo "PROCESS_TEST_RESULT_LOG=$GITHUB_WORKSPACE/$TEST_RESULT_LOG" >> $GITHUB_ENV
fi

if [[ -f "$GITHUB_WORKSPACE/$COVERAGE_PROFILE" ]] ; then
  echo "process coverage profile"
  PACKAGE=$(awk '$1 ~ /module/ { print $2 }' $GITHUB_WORKSPACE/go.mod)
  awk '{ gsub(/(\.[0-9]+,|\.[0-9]+ |:)/," "); print }' $GITHUB_WORKSPACE/$COVERAGE_PROFILE | sort -k1,1 -k2,2n | awk -f $SCRIPT_DIR/coverage_summary.awk -v package="$PACKAGE" -v baseUrl="$BASE_URL" >> $SUMMARY_FILE
  echo "PROCESS_COVERAGE_PROFILE=$GITHUB_WORKSPACE/$COVERAGE_PROFILE" >> $GITHUB_ENV
fi

if [[ "$WITH_ARCHIVE" == "true" && -f "$GITHUB_WORKSPACE/$COVERAGE_PROFILE" ]] ; then
  echo "generate html report"
  go tool cover -html $GITHUB_WORKSPACE/$COVERAGE_PROFILE -o $PROCESS_COVERAGE_REPORT
  echo "PROCESS_COVERAGE_REPORT=$PROCESS_COVERAGE_REPORT" >> $GITHUB_ENV
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

echo "PROCESS_SUMMARY=$SUMMARY_FILE" >> $GITHUB_ENV