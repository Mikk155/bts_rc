$ErrorActionPreference = "Stop"

$repositoryRoot = git rev-parse --show-toplevel
if ($LASTEXITCODE -ne 0) {
    throw "This script must be run inside the repository."
}

git -C $repositoryRoot config core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) {
    throw "Unable to configure Git hooks."
}

Write-Host "Git hooks enabled. pre-commit will run: python src/main.py --check"
