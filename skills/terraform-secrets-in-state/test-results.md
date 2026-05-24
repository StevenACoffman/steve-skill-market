# Test Results: Terraform-Secrets-in-State

## Verdict: PASS (10/10)

## Should_invoke

| ID       | Prompt (abbreviated)                                                    | Result | Notes                                                                                                                                       |
| -------- | ----------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| ss-si-01 | sensitive=true — does it protect the state file?                        | PASS   | A2 trigger exact match. I section explains sensitive=true is a display filter only, not a security control.                                 |
| ss-si-02 | Using Secrets Manager to inject RDS password — does that protect state? | PASS   | A2 trigger exact match. A1 example shows the Secrets Manager pattern still writes password to state.                                        |
| ss-si-03 | Security audit found plaintext creds in state despite using env vars    | PASS   | A2 trigger ("compliance audit asks whether state contains plaintext credentials"). E steps explain what actually protects state.            |
| ss-si-04 | How do I prevent secrets from ending up in state?                       | PASS   | A2 trigger. Answer is definitive: you cannot prevent it, only encrypt and restrict the backend. E steps give the actionable security model. |

## Should_not_invoke

| ID        | Prompt (abbreviated)                                                    | Result | Notes                                                                                                                  |
| --------- | ----------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------- |
| ss-sni-01 | Rotating IAM access keys that Terraform uses to authenticate            | PASS   | No A2 trigger. About Terraform's own auth credentials, not secrets in managed resources. Skill correctly stays silent. |
| ss-sni-02 | Accidentally committed .tfvars to git — how to remove from git history? | PASS   | No A2 trigger. Git history cleanup is separate from state file exposure. Skill stays silent.                           |
| ss-sni-03 | Using AWS KMS to encrypt an S3 bucket for application data              | PASS   | No A2 trigger. Application data encryption unrelated to Terraform state secrets. Skill stays silent.                   |

## Blurred_boundary

| ID       | Prompt (abbreviated)                                                              | Result | Notes                                                                                                                                                              |
| -------- | --------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ss-bb-01 | Vault dynamic secrets — short-lived, auto-rotated — eliminates state risk?        | PASS   | B section explicitly addresses this: dynamic secrets reduce exposure window but value still written to state at apply time. Nuanced response.                      |
| ss-bb-02 | Terraform Cloud encrypts state at rest — are secrets protected?                   | PASS   | B section explicitly addresses: TFC encrypts at rest by default, but state data exists before encryption and TFC support policies govern access. Nuanced response. |
| ss-bb-03 | Resources that only accept ARN, not secret value — still expose secrets in state? | PASS   | B section explicitly notes "resources storing only ARNs do not have this problem." Skill correctly identifies this as the safe exception.                          |
