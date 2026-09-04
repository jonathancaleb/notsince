/// The bundled alarm sounds.
///
/// Synthesised as short WAV bars that end in silence, so looping them produces
/// a steady repeating pattern rather than one run-on tone. Bundled rather than
/// pulled from the system ringtone picker: the app makes no network calls and
/// asks for no storage permissions, and a sound that is guaranteed present is
/// worth more here than one the user might have deleted.
class Ringtone {
  const Ringtone({required this.id, required this.name, required this.asset});

  final String id;
  final String name;
  final String asset;
}

const List<Ringtone> kRingtones = [
  Ringtone(id: 'chime', name: 'Chime', asset: 'assets/audio/chime.wav'),
  Ringtone(id: 'marimba', name: 'Marimba', asset: 'assets/audio/marimba.wav'),
  Ringtone(id: 'rise', name: 'Rise', asset: 'assets/audio/rise.wav'),
  Ringtone(id: 'buzzer', name: 'Buzzer', asset: 'assets/audio/buzzer.wav'),
];

const String kDefaultRingtoneId = 'chime';

Ringtone ringtoneById(String id) => kRingtones.firstWhere(
      (r) => r.id == id,
      // A sound removed in a later version must not stop an alarm ringing.
      orElse: () => kRingtones.first,
    );
