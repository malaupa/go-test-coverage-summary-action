BEGIN {
  printf("## Test Result\n\n")
  details = "<details>\n<summary>Test Details</summary>\n\n"
}
$1 ~ /===/ { 
  count++
  errorLink = ""
  error = ""
  errorSummary = ""
  next
}
$1 ~ /---/ { 
  if ( $2 ~ /FAIL:/ ) { 
    failed++ 
    details = sprintf("%s:red_circle: %s %s\n", details, $3, $4)
    details = sprintf("%s<details>\n<summary>Log</summary>\n\n%s\n\n</details>\n\n", details, errorSummary)
  }
  if ( $2 ~ /SKIP:/) {
    skipped++
    details = sprintf("%s:white_circle: %s\n", details, $3)
  }
  if ( $2 ~ /PASS:/) {
    details = sprintf("%s:green_circle: %s %s\n", details, $3, $4)
  }
  next
} 
$1 ~ /Test:/ {
  error = error$0"\n"
  errorSummary = sprintf("%s%s\n\n```\n%s```\n\n", errorSummary, errorLink, error)
  errorLink = ""
  error = ""
  next
}
{ 
  if(match($0,workspace"(.+):([0-9]+)$",e)) {
    errorLink = sprintf("[%s:%s](%s%s#L%s)", e[1], e[2], baseUrl, e[1], e[2])
  }
  error = error$0"\n" 
}
END {
  if (count > 0) {
    if (failed > 0) {
      printf(":broken_heart: %d Test(s) failed of %d Tests\n\n", failed, count)
    } else {
      printf(":raised_hands: %d Tests pass\n\n", count)
    }
    details = details"\n</details>\n\n"
    print(details)
  }
}