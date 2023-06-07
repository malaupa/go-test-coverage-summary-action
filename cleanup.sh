#!/usr/bin/bash

set -e

if [[ -f "$PROCESS_TEST_RESULT_LOG" ]] ; then
  rm "$PROCESS_TEST_RESULT_LOG"
fi

if [[ -f "$PROCESS_COVERAGE_PROFILE" ]] ; then
   rm "$PROCESS_COVERAGE_PROFILE"
fi

if [[ -f "$PROCESS_COVERAGE_REPORT" ]] ; then
  rm "$PROCESS_COVERAGE_REPORT"
fi

if [[ -f "$PROCESS_SUMMARY" ]] ; then
  rm "$PROCESS_SUMMARY"
fi
