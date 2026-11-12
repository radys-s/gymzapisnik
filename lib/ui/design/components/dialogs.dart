part of '../components.dart';

// Potvrzení, oznámení a vrácení akce.

/// Potvrzení před nevratnou akcí. Vrací `true` jen po potvrzení.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  String? message,
  required String confirm,
  String cancel = 'Zrušit',
  bool destructive = false,
}) async {
  final p = context.palette;
  final result = await showAdaptiveDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog.adaptive(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        adaptiveAction(
          dialog,
          label: cancel,
          onPressed: () => Navigator.pop(dialog, false),
        ),
        adaptiveAction(
          dialog,
          label: confirm,
          color: destructive ? p.negative : null,
          strong: true,
          onPressed: () => Navigator.pop(dialog, true),
        ),
      ],
    ),
  );
  return result == true;
}

/// Tlačítko dialogu podle platformy (na iPhonu jako v iOS).
Widget adaptiveAction(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
  Color? color,
  bool strong = false,
}) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return CupertinoDialogAction(
      onPressed: onPressed,
      isDefaultAction: strong,
      isDestructiveAction: color != null,
      child: Text(label),
    );
  }
  return TextButton(
    onPressed: onPressed,
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
      ),
    ),
  );
}

/// Krátká zpráva dole na obrazovce.
void showToast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

/// Zpráva s tlačítkem „Vrátit" po smazání.
void showUndo(BuildContext context, String message, VoidCallback onUndo) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'Vrátit', onPressed: onUndo),
        ),
      );

/// Zavře obrazovku jen jednou: druhé rychlé klepnutí během animace by
/// jinak zavřelo i obrazovku pod ní (a s ní neuložené změny).
void popOnce<T extends Object?>(BuildContext context, [T? result]) {
  final route = ModalRoute.of(context);
  if (route != null && !(route.isActive && route.isCurrent)) return;
  Navigator.pop(context, result);
}
