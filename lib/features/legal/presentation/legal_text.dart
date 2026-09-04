import 'package:notsince/core/app_info/app_info.dart';

/// The policy text, kept in the app so it is readable offline and cannot go
/// stale against a page on a website.
///
/// Google Play *also* requires a publicly reachable privacy policy URL on the
/// store listing, so this same text has to be published at
/// [AppInfo.privacyUrl] before submitting. Shipping it in-app alone will fail
/// review.
///
/// It is short because the app genuinely does very little: an app that
/// collects nothing needs no clauses about what it does with what it collects.
abstract final class LegalText {
  static const privacyTitle = 'Privacy policy';

  static final privacy = '''
Last updated ${AppInfo.policyUpdated}

The short version
${AppInfo.name} collects nothing, sends nothing and stores nothing outside your device. There is no account to create, no server to talk to, and no analytics of any kind.

What the app stores
Everything you enter — the habits you track, their start times, milestones and history, your alarms, and your notes and tasks — is written to a database file inside the app's own private storage on your phone. Android prevents other apps from reading it.

What the app sends
Nothing. ${AppInfo.name} makes no network requests. It has no advertising, no crash reporting, no usage analytics and no third-party tracking libraries. Fonts and alarm sounds are bundled with the app rather than downloaded.

Permissions and why they are needed
• Notifications — an alarm rings from a foreground service, which cannot run without permission to post its notification.
• Alarms and reminders (exact alarms) — so an alarm rings at the time you set rather than whenever the system next decides to wake the app.
• Vibration, wake lock, run at startup — so an alarm can vibrate, wake the screen, and survive the phone being restarted.
None of these permissions are used to collect information.

Children
${AppInfo.name} is not directed at children and collects no personal information from anyone, of any age.

Deleting your data
Settings contains "Remove all data", which erases everything the app has stored. Uninstalling the app also removes it. Because nothing is ever sent anywhere, there is nothing else to delete and nothing to request a copy of.

Changes
If this policy changes, the date at the top changes with it, and the current version always ships inside the app.

Contact
${AppInfo.contactEmail}
''';

  static const termsTitle = 'Terms of use';

  static final terms = '''
Last updated ${AppInfo.policyUpdated}

Using the app
${AppInfo.name} is provided free of charge for personal use. You may use it however you like on devices you control.

What it is not
${AppInfo.name} is a self-tracking tool. It is not a medical device and not a treatment programme, and nothing in it is medical, psychological or clinical advice. If you are managing a dependency or a health condition, please talk to a qualified professional. The app does not diagnose anything, does not monitor your wellbeing, and cannot help in a crisis.

Alarms
The app schedules alarms through Android's own alarm service and does everything it can to make them ring, including through silent mode. Whether an alarm actually rings still depends on your device: battery optimisation, manufacturer power-saving, Do Not Disturb rules, force-stopping the app or revoking its permissions can all prevent it. Please do not rely on ${AppInfo.name} alone for something that genuinely matters.

Your data is your responsibility
Everything is stored only on your device and is never backed up anywhere by the app. If you uninstall the app, reset the device or clear its storage, your data is gone and cannot be recovered.

No warranty
The app is provided "as is", without warranty of any kind. To the extent the law allows, the developer is not liable for any loss arising from using it — including a missed alarm or lost data.

Changes
These terms may change with new versions. The current version always ships inside the app.

Contact
${AppInfo.contactEmail}
''';
}
