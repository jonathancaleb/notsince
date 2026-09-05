/// Facts about the app that the store listing, the legal pages and the about
/// screen all have to agree on. Changing an address means changing it here.
abstract final class AppInfo {
  static const name = 'notsince';
  static const packageId = 'app.notsince';

  /// Keep in step with `version:` in pubspec.yaml.
  static const version = '1.0.0';
  static const developer = 'Caleb';
  static const contactEmail = 'sabilacalebj@gmail.com';
  static const privacyUrl = 'https://services.jakisatech.com/#notsince';
  static const termsUrl = 'https://services.jakisatech.com/#notsince';

  /// The date the policy text below was last changed.
  static const policyUpdated = '4 September 2026';
}
