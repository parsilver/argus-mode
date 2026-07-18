# Secret-shaped strings the shipped regex-sweep MUST flag

This fixture is deliberately-planted test data for check 24 in
`tests/run-checks.sh`. It carries no live credential: the AWS key is the
documented `...EXAMPLE` non-secret, the PEM line is a bare header with no key
body, and the assignment value is a fabricated hex string. Real scans exclude
this path by a named allowlist (see `references/verification.md`).

aws_access_key_id = AKIAIOSFODNN7EXAMPLE

-----BEGIN RSA PRIVATE KEY-----

service_token = abcdef0123456789ABCDEF0123456789
