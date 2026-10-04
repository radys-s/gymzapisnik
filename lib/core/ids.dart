import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();

/// Stejné ID pro dokončení stejného rozepsaného tréninku, takže dvojí
/// dokončení nevytvoří duplicitu v historii.
String completedWorkoutId(String activeId) =>
    _uuid.v5(Namespace.url.value, 'gymzapisnik/workout/$activeId');
