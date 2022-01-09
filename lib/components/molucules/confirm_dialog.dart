import 'package:flutter/cupertino.dart';

class ConfirmDialog extends StatelessWidget {
  final String content;
  final VoidCallback onPressedOk;
  const ConfirmDialog(
      {Key? key, required this.content, required this.onPressedOk})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Alert'),
      content: Text(content),
      actions: [
        CupertinoDialogAction(
            child: const Text('Cancel'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context)),
        CupertinoDialogAction(child: const Text('OK'), onPressed: onPressedOk),
      ],
    );
  }
}
