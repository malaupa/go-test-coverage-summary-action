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
  if (match($1,"^"package"(.+)$",f)) {
    if (file != "" && file != f[1] ) {
      # write file entry with coverage and uncovered lines
      fileCoverage = fileCovered/fileStatements*100
      if (lineStart != "" && lineEnd != "") {
        if (uncoveredLines != "") {
          uncoveredLines = uncoveredLines", "
        }
        uncoveredLines = sprintf("%s[%s-%s](%s%s#L%s-L%s)", uncoveredLines, lineStart, lineEnd, baseUrl, file,  lineStart, lineEnd)
      }
      details = sprintf("%s|%s %.1f%|%s|%s|\n", details, bar(fileCoverage), fileCoverage, file, uncoveredLines)
      fileCovered = 0
      fileStatements = 0
      uncoveredLines = ""
      lineStart = ""
      lineEnd = ""
    }
    # start new file coverage measuring
    file = f[1]
    statements += $4
    fileStatements += $4
    if ($5 != "0") {
      # covered lines
      covered += $4
      fileCovered += $4

      if (lineStart != "" && lineEnd != "") {
        if (uncoveredLines != "") {
          uncoveredLines = uncoveredLines", "
        }
        uncoveredLines = sprintf("%s[%s-%s](%s%s#L%s-L%s)", uncoveredLines, lineStart, lineEnd, baseUrl, file,  lineStart, lineEnd)
        lineStart = ""
        lineEnd = ""
      }

      next
    } 
    # not covered lines
    if (lineStart == "") {
      lineStart = $2
    }
    lineEnd = $3
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