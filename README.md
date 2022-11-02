# gitleaks-action

This is a centralized repository to maintain the github actions in an organization.

## Usage

use the gitleaks.yml as the workflow file. Place it inside the `.github/workflows/gitleaks.yml`

## Reminder

Don't forget to add the token incase you are making this repository as a private repo in your organization. Add the token in your org wide secrets for better security and ease.

Add the following line in the gitleaks.yml workflow file.

token: ${{ GIT_PAT }}
