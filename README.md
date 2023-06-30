# go-test-coverage-summary-action
Action to show test and coverage summary as job summary and pull request comment.

## Inputs

### `test_results`
Defines verbose test output file. Defaults to `test.out`.

### `coverage_profile`
Defines coverage profile output file. Defaults to `cover.out`.

### `with_archive`
Enables coverage html report as job artifact attachment. Defaults to `false`.

### `github_token`
Used to comment pull requests. Defaults to `${{ github.token }}`.

## Example usage
```
- name: Run test
  run: go test -v -coverprofile cover.out ./... | tee test.out
  shell: bash
- name: Process results
  if: always()
  uses: malaupa/go-test-coverage-summary-action@v2.0.0
  with:
    test_results: "test.out"
    coverage_profile: "cover.out"
    with_archive: true
```

## Example Pull Request Comment

![Screenshot](/screenshot.png)
