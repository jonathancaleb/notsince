import 'package:hive_ce/hive.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';
import 'package:notsince/features/alarms/domain/ringtone.dart';
import 'package:notsince/features/counter/domain/milestones.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/features/counter/domain/tracker_run.dart';
import 'package:notsince/features/notes/domain/note.dart';

/// The only file in the app that imports both Hive and the domains.
///
/// hive_ce generates adapters for classes it does not own, so domain classes
/// stay free of `@HiveType`/`@HiveField` and free of any Hive import. This also
/// has to be a single file: hive_ce rejects a second `@GenerateAdapters` in the
/// same package, so feature-first folders cannot each own their adapter.
///
/// Type ids and field indices are assigned once and then pinned in the
/// generated `hive_adapters.g.yaml`. That file is the schema of record and must
/// be committed — deleting it would renumber existing data.
@GenerateAdapters([
  AdapterSpec<Tracker>(),
  AdapterSpec<TrackerRun>(),
  AdapterSpec<AlarmEntry>(),
  AdapterSpec<Note>(),
])
part 'hive_adapters.g.dart';
