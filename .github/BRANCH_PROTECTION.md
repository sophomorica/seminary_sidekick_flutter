# GitHub Branch Protection Configuration

## Recommended Settings for `main` branch:

### Branch protection rules:
- ✅ Require a pull request before merging
- ✅ Require approvals (1 reviewer minimum)
- ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging

### Required status checks:
- ✅ `test (Run Flutter Tests)` - from the flutter-ci.yml workflow

### Include administrators:
- ✅ Enforce these rules for administrators too

## Setup Instructions:

1. Go to your repository on GitHub
2. Navigate to Settings → Branches
3. Click "Add rule" for the `main` branch
4. Configure the settings as above
5. Save the rule

This ensures all PRs are tested and reviewed before merging to main.