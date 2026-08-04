az login --tenant e00f439d-ba7d-4cb3-987f-c4fc51f7671d --allow-no-subscriptions

TOKEN_LIFETIME_POLICY_ID=$(az rest \
    --method POST \
    --url "https://graph.microsoft.com/v1.0/policies/tokenLifetimePolicies/" \
    --headers "Content-Type=application/json" \
    --body '{
    "definition": [
        "{\"TokenLifetimePolicy\":{\"Version\":1,\"AccessTokenLifetime\":\"08:00:00\"}}"
    ],
    "displayName": "8 hour policy",
    "isOrganizationDefault": false
}' | jq -r '.id') # b74d31bc-07d6-4038-811c-0b1762d51e0e

ACCOMPIOGPT_CLIENT_ID="feb4a8e8-d78d-4627-8462-f3815efdd9ee"
ACCOMPIOGPT_OBJECT_ID="61e0b8d7-cb1d-427e-9336-d113243723ad"

az rest \
  --method POST \
  --url "https://graph.microsoft.com/v1.0/servicePrincipals/$ACCOMPIOGPT_OBJECT_ID/tokenLifetimePolicies/\$ref" \
  --headers "Content-Type=application/json" \
  --body '{
    "@odata.id": "https://graph.microsoft.com/v1.0/policies/tokenLifetimePolicies/'$TOKEN_LIFETIME_POLICY_ID'"
  }'
