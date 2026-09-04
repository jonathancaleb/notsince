import 'dart:math';

final _random = Random();

/// Ids only have to be unique within one device's boxes.
///
/// The timestamp alone is not enough: its resolution varies by platform, so two
/// records created in the same tick would collide and the second would
/// overwrite the first. It is also not monotonic — a clock change can move it
/// backwards. The random salt is what guarantees uniqueness; the timestamp just
/// keeps ids roughly ordered by creation.
String newId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final salt = _random.nextInt(1 << 32).toRadixString(36);
  return '$time-$salt';
}
