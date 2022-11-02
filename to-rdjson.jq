# Convert Gitleaks JSON output to Reviewdog Diagnostic Format (rdjson)
# https://github.com/reviewdog/reviewdog/blob/f577bd4b56e5973796eb375b4205e89bce214bd9/proto/rdf/reviewdog.proto
{
  source: {
    name: "gitleaks",
    url: "https://github.com/zricethezav/gitleaks"
  },
  diagnostics: map({
    message: (.Match + " (" + .RuleID + ")"),
    code: {
      value: "https://github.com/contentful/security-tools-config/issues/new?title=False%20positive%20in%20Gitleaks&body=Put%20Action%20Run%20URL%20here%20(for%20e.g%20https%3A%2F%2Fgithub.com%2Fkarankohli-cf%2Ftest-reviewdog-tf-actions%2Factions%2Fruns%2F3381508479%2Fjobs%2F5615488954)",
      url: "False Positive? Report to team-security"
    },
    location: {
      path: .File,
      range: {
        start: {
          line: .StartLine,
        },
      }
    },
    severity: "ERROR", 
  })
}