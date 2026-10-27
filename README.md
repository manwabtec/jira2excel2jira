# jira2excel2jira
Convert all jira elements to excel columns and from there any updates should be send back to jira. 

## Commit and Sync Main

Use Git Bash on Windows, or Bash on macOS/Linux.

Enter your commit author identity, GitHub username, and a personal access token
in the local `.env` file:

```dotenv
GIT_USER_NAME='Your Name'
GIT_USER_EMAIL='you@example.com'
GIT_USERNAME='your-github-username'
GIT_TOKEN='your-personal-access-token'
```

The script writes `GIT_USER_NAME` and `GIT_USER_EMAIL` to this repository's
local Git config only (`.git/config`); global Git settings are not changed.
Set both identity fields together. If both are blank, an existing usable Git
identity is required. The author identity is separate from authentication.

The token needs permission to write repository contents. `.env` is ignored by
Git; never commit or share it. After cloning, create it from `.env.example`.
The file is sourced as Bash, so use shell quoting and only load trusted content.
Leave `GIT_USERNAME` and `GIT_TOKEN` empty to use your existing Git credential
manager instead.
The token is supplied through a temporary askpass helper, not the remote URL
or command arguments, and is not saved by Git's credential helpers.

From `main`, run:

```bash
bash sync-main.sh "Describe your changes"
```

The script stages **all** changes, commits them (if any), pulls `origin/main`
with a merge rather than a rebase, and pushes `main` to `origin`. It does not
switch branches, force-push, or bypass branch protection. The default commit
message is `Update current changes` when no message is supplied.

If the pull conflicts, nothing is pushed. Resolve the conflicts and commit the
merge, or run `git merge --abort`, then rerun the script. Local commits remain
available if authentication, network access, or a protected branch blocks sync.
