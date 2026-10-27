# Schmoose — How to log in

Schmoose offers several ways to sign in. Which ones appear on the login
screen depends on what the operator has enabled, and some of them must be
prepared from an already signed-in session first.

| Way | Needs | Best for |
|---|---|---|
| Password (+ 2FA) | account with a password | everyday sign-in |
| SSO | operator enabled OIDC | company accounts |
| Sign in with this device | a paired phone/device | one-tap return |
| Sign in with QR | a phone with camera + a signed-in desktop | phones & tablets |
| Login file | a `.key` file + one-time passphrase | home computers, no camera |

---

## 1. Password (+ two-factor)

Type your **username or email** and your password, then **Sign in**.

If the account has 2FA enabled, a second field appears — enter the 6-digit
code from your authenticator app, or one of your recovery codes
(`XXXX-XXXX`). Recovery codes are shown once when you activate 2FA
(Profile & security → Two-factor authentication).

## 2. SSO (single sign-on)

If the operator connected Schmoose to an identity provider (Keycloak), a
**"Sign in with SSO"** button is shown. It redirects you to the company
login page; after signing in there you land back in Schmoose. Password and
2FA for such accounts are managed at the identity provider, not in
Schmoose's profile dialog.

## 3. Sign in with this device (one tap)

After a device has been paired once (via QR, below), the login screen
remembers it — the **"Sign in with this device"** button lights up and
signs you in with one tap. The device secret is stored in the browser's
IndexedDB in a non-extractable form; nothing readable to steal.

Paired devices stay valid as long as they are used (sliding 42-day window).
You can revoke any device at any time: **Profile & security → Devices →
Remove**.

## 4. Sign in with QR (phone + desktop)

For a **phone or tablet** (anything with a camera), while sitting at a
desktop that is already signed in:

1. Desktop: **Profile & security → Devices → Add device** — a QR code
   appears.
2. Phone: open Schmoose, tap **Sign in with QR**, point the camera at the
   code.
3. The desktop shows who is asking (device label) — **approve** it.
   This human step is the security core: a photographed QR code alone never
   grants access.

The phone is now paired — one-tap sign-ins from then on, and it appears in
the desktop's Devices list (with platform info and first-connected date).

## 5. Login file (home computers, no camera)

A desktop computer can't scan a QR code. For those, export a **login
file** plus a one-time **passphrase** from a signed-in session:

**Create (on a machine that is signed in):**

1. **Profile & security → Login files → Create login file** (optional:
   give it a label like "office MacBook").
2. A panel shows the passphrase — **four words and two digits**, e.g.
   `kernel-mascot-tundra-vibes-42`. It is **shown only once**: store it in
   your password manager now.
3. Click **Download .key file** — you get
   `schmoose-login-<date>.key`.

**Use (on the home computer):**

1. On the Schmoose login screen, switch to the **"Login file"** tab.
2. Choose the `.key` file, type the passphrase, **Sign in with file**.

You are signed in like on any other device — the machine appears in your
Devices list.

**Good to know:**

- A login file works **once**. After a successful sign-in it is consumed.
- It **expires after 30 days** — create a fresh one before that if needed.
- **5 wrong passphrases burn the file** (it becomes unusable, the error
  stays generic). Create a new one in that case.
- Keep the file and the passphrase apart: either alone is worthless, only
  together do they open the door.
- You can see all active files and revoke them in
  **Profile & security → Login files** (Revoke = the file is dead
  immediately).

---

## Sessions and what they allow

Every sign-in creates a session. Password and SSO sessions may manage
password/2FA settings in the profile; **device sessions** (QR, one-tap,
login file) deliberately may not — sign in with your password to manage
those. SSO-only accounts manage credentials at their identity provider and
cannot mint login files.

## Troubleshooting

| Symptom | Meaning |
|---|---|
| "File and passphrase do not match — or the file is used up, burned or expired" | Wrong passphrase, already-used, burned or expired file — create a new one in the profile. |
| "Sign in with this device" is grey/dark | No paired device in this browser — pair once via QR. |
| Device gone from the Devices list / login rejected after long disuse | Sliding 42-day window expired or the device was revoked — pair again (or use a login file). |
| Camera scanner won't open | Camera permission denied — use the password, SSO or a login file instead. |
