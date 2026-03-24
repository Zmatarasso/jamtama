// Usage: dart run tool/hot_reload.dart
// Triggers a Flutter hot reload via the Dart VM service.
// Requires the app to be running with --vmservice-out-file .flutter-vmservice

import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() async {
  final urlFile = File('.flutter-vmservice');
  if (!urlFile.existsSync()) {
    print('ERROR: .flutter-vmservice not found. Is the app running?');
    exit(1);
  }

  final serviceUrl = urlFile.readAsStringSync().trim();
  final wsUrl = serviceUrl.replaceFirst(RegExp(r'^http'), 'ws') + 'ws';

  WebSocket socket;
  try {
    socket = await WebSocket.connect(wsUrl);
  } catch (e) {
    print('ERROR: Could not connect to VM service at $wsUrl\n$e');
    exit(1);
  }

  final done = Completer<void>();

  socket.listen((message) async {
    final msg = jsonDecode(message as String) as Map<String, dynamic>;

    if (msg['id'] == '1') {
      final isolates =
          (msg['result']['isolates'] as List).cast<Map<String, dynamic>>();
      final isolate = isolates.firstWhere(
        (i) => (i['name'] as String).contains('main'),
        orElse: () => isolates.first,
      );
      socket.add(jsonEncode({
        'jsonrpc': '2.0',
        'id': '2',
        'method': 'reloadSources',
        'params': {'isolateId': isolate['id']},
      }));
    } else if (msg['id'] == '2') {
      if (msg['result'] != null) {
        final count = msg['result']['reloadedLibraryCount'] ?? '?';
        print('Hot reload complete ($count libraries reloaded)');
      } else {
        print('Hot reload failed: ${msg['error']}');
      }
      await socket.close();
      done.complete();
    }
  });

  socket.add(jsonEncode({
    'jsonrpc': '2.0',
    'id': '1',
    'method': 'getVM',
    'params': {},
  }));

  await done.future;
}
