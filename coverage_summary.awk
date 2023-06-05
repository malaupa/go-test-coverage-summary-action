function bar(cov) {
  if (cov >= 95) {
      return ":green_square::green_square::green_square::green_square:"
    } else if (cov >= 75) {
      return ":green_square::green_square::green_square::red_square:"
    } else if (cov >= 50) {
      return ":green_square::green_square::red_square::red_square:"
    } else if (cov >= 25) {
      return ":green_square::red_square::red_square::red_square:"
    } else {
      return ":red_square::red_square::red_square::red_square:"
    }
}

BEGIN {
  printf("## Coverage\n\n")
  details = "<details>\n<summary>Coverage Details</summary>\n\n"
  details = details"|Coverage|File|Uncovered Lines|\n"
  details = details"|-|-|-|\n"
  file = ""
}
$1 !~ /mode:/ {
  if (match($1,"^"package"([^:]+):([0-9]+).[0-9]+,([0-9]+).[0-9]+",f)) {
    if (file != "" && file != f[1] ) {
      fileCoverage = fileCovered/fileStatements*100
      if (lineStart != "" && lineEnd != "") {
        uncoveredLines = sprintf("%s[%s-%s](%s%s#L%s-L%s)", uncoveredLines, lineStart, lineEnd, baseUrl, file,  lineStart, lineEnd)
      }
      details = sprintf("%s|%s %.1f%|%s|%s|\n", details, bar(fileCoverage), fileCoverage, file, uncoveredLines)
      fileCovered = 0
      fileStatements = 0
      uncoveredLines = ""
      lineStart = ""
      lineEnd = ""
    } 
    file = f[1]
    statements += $2
    fileStatements += $2
    if ($3 != "0") {
      covered += $2
      fileCovered += $2
      next
    } 
    if (lineStart == "" && lineEnd == "") {
      lineStart = f[2]
      lineEnd = f[3]
      next
    }
    if (lineEnd+0 == f[2]+0 || lineEnd+1 == f[2]+0) {
      lineEnd = f[3]
      next
    } 
    uncoveredLines = sprintf("%s[%s-%s](%s%s#L%s-L%s), ", uncoveredLines, lineStart, lineEnd, baseUrl, file,  lineStart, lineEnd)
    lineStart = f[2]
    lineEnd = f[3]
  }
}
END {
  if (statements > 0) {
    total = covered/statements*100
    printf("Total coverage: %s %.1f%\n", bar(total), total)
    details = details"\n</details>\n\n"
    print(details)
  }
}