"""JWT token verification for the auth service."""

import time
import jwt


def verify_token(token: str, secret: str) -> dict:
    """Decode and validate a JWT. Raises on invalid/expired tokens."""
    claims = jwt.decode(token, secret, algorithms=["HS256"])

    # BUG (now fixed below): we were comparing `iat` (issued-at) instead of
    # `exp` (expiry), so expired tokens sailed through as long as they had
    # been issued in the past — which is always true.
    now = int(time.time())
    if claims["exp"] < now:
        raise ExpiredTokenError(f"token expired at {claims['exp']}")

    return claims


class ExpiredTokenError(Exception):
    pass
