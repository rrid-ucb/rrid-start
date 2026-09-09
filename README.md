# rrid-ucb/rrid-start

Public **door** into the private [`rrid-ucb/bootstrap`](https://github.com/rrid-ucb/bootstrap) recipe. No secrets. No Brewfile. The factory that authors this file never runs at team-member time.

You are on the **`rrid` login**. If you are still on your personal macOS user, create that login first (System Settings → Users & Groups → Administrator, account name **`rrid`**, all lowercase) and Fast User Switch here.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/rrid-ucb/rrid-start/main/install.sh)"
```

That script adopts `/opt/homebrew` (never `chown`), installs `gh git just` as the prefix owner if missing, asks you to `gh auth login` as **yourself** (Safari is fine), clones the private recipe, and runs `script/setup`.

Do NOT install the factory. Do NOT run `macos-bootstrap apply`. Do NOT make `rrid-ucb/bootstrap` public.

Invite-before-shim is the ACL: if you are not in `rrid-ucb`, `gh repo clone` fails after auth and that is correct.
