# False-positive traps the shipped regex-sweep must NOT flag

Each line below is something a naive high-entropy scanner would flag but a
keyword-anchored, value-length-bounded sweep must not. Check 24 asserts zero
hits here.

This guide explains how the secret rotation works.
The token is refreshed on login; see the auth module.
Store your API key in the environment, never in code.
password: hunter2
SECRET_KEY=<your-key-here>
api_key = REDACTED
See commit 3639d287b6834bd6d2a0bc5f7240c23322326076 for details.
