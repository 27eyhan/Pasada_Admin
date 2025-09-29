# Security Policy

Thank you for helping keep this project and its users safe.

## Supported Versions

We provide security fixes for the latest stable branch and the most recent minor release.

| Version        | Supported          |
|----------------|--------------------|
| main (active)  | Yes                |
| <= older tags  | No                 |

If you are using a forked or modified build, please cherry-pick security fixes promptly.

## Reporting a Vulnerability

- **Email**: security@example.com
- **Alternative**: Open a private advisory via GitHub Security Advisories (preferred) or send an encrypted email (PGP key below).
- **What to include**:
  - Affected version/commit and platform (Android/iOS/Web/Windows/macOS/Linux)
  - Steps to reproduce, proof-of-concept, and impact
  - Any logs or screenshots
  - Your contact and preferred disclosure timeline

We aim to acknowledge within 3 business days and provide a remediation plan or fix within 30 business days, depending on severity and complexity.

### Encryption (optional)
PGP: https://example.com/pgp.txt
Fingerprint: 0000 0000 0000 0000 0000  0000 0000 0000 0000 0000

## Coordinated Disclosure Policy

- Please do not publicly disclose or share details with third parties until we release a fix and coordinated advisory.
- We follow CVSS v3.1 for severity and will credit reporters (unless you prefer anonymity).
- If a fix is delayed, we will provide regular status updates and an interim mitigation when possible.

## Scope

This policy covers the code and configurations in this repository:
- Flutter/Dart application code under `lib/`, `widgets/`, `services/`, etc.
- Platform integrations (`android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`)
- Project configuration and deployment artifacts (e.g., `vercel.json`, `web/`, `assets/`)

Out of scope: issues in third-party dependencies (report to upstream), social engineering, DoS without a clear defect, or issues requiring privileged/local access without a bypass.

## Handling Sensitive Data

- Never commit secrets (API keys, tokens, keystores). Use environment variables or secure storage.
- Verify `.gitignore` covers secret files, keystores, and build artifacts.
- Rotate credentials that may have been exposed during testing or reporting.

## Dependency Security

- Use `flutter pub outdated --mode=null-safety` and update regularly.
- Pin critical dependencies and review changelogs for security notes.
- Enable supply-chain safeguards (e.g., checksums, reproducible builds where possible).

## Platform-Specific Guidance

### Android
- Sign release builds with a secure keystore; store keystores outside the repo.
- Enable minification/obfuscation (R8) for release builds where compatible.
- Configure `networkSecurityConfig` to disallow cleartext traffic unless explicitly required.
- Target a current SDK; keep `compileSdkVersion`/`targetSdkVersion` up-to-date.

### iOS/macOS
- Use proper code signing and secure distribution profiles.
- Enforce ATS (App Transport Security) with TLS; only add exceptions when necessary.

### Web
- Prefer HTTPS everywhere; set HSTS at the origin.
- Use a restrictive CSP (adjust paths as needed):
  - Example CSP:
    Content-Security-Policy: default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https://api.example.com; frame-ancestors 'none'; base-uri 'self';
- Set security headers:
  - X-Content-Type-Options: nosniff
  - X-Frame-Options: DENY
  - Referrer-Policy: no-referrer
  - Permissions-Policy: geolocation=(), camera=(), microphone=()
- Avoid embedding secrets in `web/index.html` or client JS.

### Desktop (Linux/Windows)
- Sign installers/binaries where applicable.
- Store user data in platform-appropriate directories with least privileges.

## Secure Coding Practices

- Validate and sanitize all external inputs; avoid trusting client-side checks.
- Use HTTPS/TLS 1.2+ for all network calls in `services/`.
- Handle auth tokens with least privilege; prefer short-lived tokens and secure storage.
- Avoid logging secrets or PII; scrub logs before sharing.
- Fail closed: on network or parsing errors, avoid unsafe defaults.

## Build & Release

- Separate debug and release configs; disable debug flags in production.
- Rebuild dependencies from clean state for releases.
- Tag releases and include security notes and migration steps in changelogs.

## Incident Response

If you believe this repository is actively being exploited:
1. Contact me immediately at athrundiscinity@protonmail.com with “URGENT” in the subject.
2. Provide version, platform, and impact.
3. We will prioritize triage, prepare a hotfix/mitigation, and publish an advisory.

## Hall of Fame

We appreciate responsible disclosures and will credit contributors in release notes unless anonymity is requested.

---

Last updated: 2025-09-29
