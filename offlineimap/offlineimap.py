"""offlineimap pythonfile: OAuth2 tokens come from ortie, not offlineimap's
own refresh machinery. oauth2_access_token_eval calls this per connection;
-r makes ortie refresh the cached access token first if it's stale, so this
always hands back a token that's actually still valid.
"""

import subprocess

def get_ortie_token(account_name):
    cmd = ["ortie", "token", "show", "-a", account_name, "-r"]
    return subprocess.check_output(cmd).strip().decode("utf-8")

def get_pass(entry):
    """Plain-password accounts (not OAuth2): first line of a pass(1) entry."""
    cmd = ["pass", "show", entry]
    return subprocess.check_output(cmd).decode("utf-8").split("\n")[0]
