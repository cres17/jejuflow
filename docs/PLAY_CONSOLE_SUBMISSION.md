# Google Play Console Submission Notes

Last reviewed: 2026-05-12

These notes are prepared for the JejuFlow Android release. They are based on the current app behavior in this repository and should be reviewed again before each production release.

## Set Privacy Policy

- Status: Required.
- Recommended URL: publish `docs/PRIVACY_POLICY.md` as a public, non-editable web page and use that URL in Play Console.
- App name in policy: JejuFlow.
- Privacy contact: add the developer support email used in the Play Console listing before publishing.

Google Play requires a privacy policy URL for apps, and the policy should describe accessed, collected, used, and shared user data, secure handling, retention, deletion, and a contact method.

Reference: https://support.google.com/googleplay/android-developer/answer/9888076

## App Access

- Select: All functionality is available without special access.
- Login required: No.
- Paid access or restricted organization access: No.
- Reviewer instructions: Open the app and choose a language. The core Now, Move, Routes, and Settings screens are accessible without an account.

## Ads

- Select: No, this app does not contain ads.
- Ad SDKs found in current app dependencies: None known.
- Advertising ID usage: None known.

Reference: https://support.google.com/googleplay/android-developer/answer/9857753

## Content Rating

Suggested answers for the rating questionnaire:

- App category: Travel / Local information.
- Violence, fear, sexual content, gambling, drugs, user-generated content: No.
- Location sharing with other users: No.
- Online purchases: No.
- Browser or unrestricted web access: No general-purpose browser. The app may open external map or destination links for travel functionality.

Expected rating should be suitable for a general travel audience, subject to the official questionnaire result.

Reference: https://support.google.com/googleplay/android-developer/answer/9859655

## Target Audience

- Recommended target age: 13 and over.
- Designed for children: No.
- Primary audience: Travelers and local visitors planning Jeju Island trips.
- Reasoning: The app uses location-related travel features and external public data APIs, and it is not specifically designed for children.

Reference: https://support.google.com/googleplay/android-developer/answer/9867159

## Data Safety

Declare based on current implementation:

| Data type | Collected | Shared | Purpose | Notes |
|---|---:|---:|---|---|
| Approximate location | Yes, if permission is granted | No | App functionality, personalization | Used to recommend nearby Jeju destinations and travel context. |
| Precise location | Yes, if permission is granted | No | App functionality, personalization | Android manifest requests fine location. Do not declare precise location if the released build never requests or uses it. |
| App activity / saved routes | Yes, local only | No | App functionality | Saved route data is stored on the device using local storage. |
| Device or other IDs | No known collection by app code | No | Not used | Recheck if analytics, crash reporting, ads, or push provider SDKs are added. |
| Personal info | No | No | Not used | No account, name, email, or profile collection in current app. |
| Photos, videos, audio, files | No | No | Not used | Not requested by current app. |
| Financial info | No | No | Not used | No payments or financial features. |
| Health and fitness | No | No | Not used | No health features. |

Security and handling:

- Data is transmitted over HTTPS where public API endpoints support it.
- API keys and signing keys must stay out of Git.
- The app does not provide account creation, so there is no account deletion flow.
- Users can clear app data from Android system settings to remove local saved routes and preferences.

Reference: https://support.google.com/googleplay/android-developer/answer/10787469

## Government Apps

- Select: No.
- JejuFlow is not developed by or on behalf of a government entity.
- It may use public data APIs, but that does not make the app a government app.

## Financial Features

- Select: No financial features.
- No banking, lending, investing, insurance, cryptocurrency, trading, payments, or money transfer features are present.

## Health

- Select: No health features.
- The app does not provide medical, health, fitness, diagnosis, treatment, or wellness tracking functionality.

## Final Release Checklist

- Confirm the public privacy policy URL is live and accessible without login.
- Confirm `.env`, `android/key.properties`, and keystore files are not tracked by Git.
- Confirm Play Console Data safety answers match the exact build being uploaded.
- Rebuild the release AAB after any version or policy-related code changes.
