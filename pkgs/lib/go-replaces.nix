{
  go-output-src,
  go-finding-src,
  cmdguard-src,
  go-branded-id-src,
  go-commit-src,
  go-filewatcher-src,
  project-discovery-sdk-src,
  gogenfilter-src,
  go-composable-business-types-src,
  art-dupl-src,
  buildflow-src,
  branching-flow-src,
  code-duplicate-analyzer-src,
  go-auto-upgrade-src,
  go-functional-fixer-src,
  go-structure-linter-src,
  hierarchical-errors-src,
  library-policy-src,
  md-go-validator-src,
  project-meta-src,
  projects-management-automation-src,
  template-readme-src,
  terraform-diagrams-aggregator-src,
  terraform-to-d2-src,
  golangci-lint-auto-configure-src,
}: ''
  replace github.com/larsartmann/go-output => ${go-output-src}
  replace github.com/larsartmann/go-finding => ${go-finding-src}
  replace github.com/larsartmann/cmdguard => ${cmdguard-src}
  replace github.com/larsartmann/go-branded-id => ${go-branded-id-src}
  replace github.com/LarsArtmann/go-commit => ${go-commit-src}
  replace github.com/larsartmann/go-filewatcher => ${go-filewatcher-src}
  replace github.com/LarsArtmann/project-discovery-sdk => ${project-discovery-sdk-src}
  replace github.com/LarsArtmann/gogenfilter => ${gogenfilter-src}
  replace github.com/larsartmann/go-composable-business-types => ${go-composable-business-types-src}
  replace github.com/LarsArtmann/art-dupl => ${art-dupl-src}
  replace github.com/larsartmann/buildflow => ${buildflow-src}
  replace github.com/larsartmann/branching-flow => ${branching-flow-src}
  replace github.com/LarsArtmann/code-duplicate-analyzer => ${code-duplicate-analyzer-src}
  replace github.com/larsartmann/go-auto-upgrade => ${go-auto-upgrade-src}
  replace github.com/LarsArtmann/go-functional-fixer => ${go-functional-fixer-src}
  replace github.com/larsartmann/go-structure-linter => ${go-structure-linter-src}
  replace github.com/larsartmann/hierarchical-errors => ${hierarchical-errors-src}
  replace github.com/LarsArtmann/library-policy => ${library-policy-src}
  replace github.com/larsartmann/md-go-validator => ${md-go-validator-src}
  replace github.com/LarsArtmann/project-meta => ${project-meta-src}
  replace github.com/LarsArtmann/projects-management-automation => ${projects-management-automation-src}
  replace github.com/LarsArtmann/template-readme => ${template-readme-src}
  replace github.com/larsartmann/terraform-diagrams-aggregator => ${terraform-diagrams-aggregator-src}
  replace github.com/larsartmann/terraform-to-d2 => ${terraform-to-d2-src}
  replace github.com/larsartmann/golangci-lint-auto-configure => ${golangci-lint-auto-configure-src}
''
