def lambda_handler(event: dict, context) -> dict:
    """Cognito Pre Token Generation (V2_0) trigger.

    Cognito access tokens carry no group membership by default — only
    the ID token does. This copies the caller's group membership into a
    `groups` claim on the access token (comma-joined, since custom claim
    values must be strings) so the API can authorize by group without
    also having to verify the ID token.
    """
    groups = event["request"]["groupConfiguration"].get("groupsToOverride", [])

    event["response"] = {
        "claimsAndScopeOverrideDetails": {
            "accessTokenGeneration": {
                "claimsToAddOrOverride": {
                    "groups": ",".join(groups),
                }
            }
        }
    }

    return event
