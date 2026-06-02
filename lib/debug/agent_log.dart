import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Debug-session logging (session 089640). Folded at call sites via #region.
class AgentDebugLog {
  static const _sessionId = '089640';
  static const _ingestPath =
      '/ingest/29a457ac-07a5-4a88-ab9b-e767fed41a47';
  static const _logPath =
      '/home/dime/Projects/BuyWme/.cursor/debug-089640.log';

  static String get _ingestHost {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:7651';
    }
    return 'http://127.0.0.1:7651';
  }

  static void log(
    String location,
    String message, {
    Map<String, dynamic>? data,
    String? hypothesisId,
    String runId = 'pre-fix',
  }) {
    final payload = <String, dynamic>{
      'sessionId': _sessionId,
      'location': location,
      'message': message,
      'data': data ?? <String, dynamic>{},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      if (hypothesisId != null) 'hypothesisId': hypothesisId,
      'runId': runId,
    };
    final line = jsonEncode(payload);

    // #region agent log
    try {
      File(_logPath).writeAsStringSync('$line\n', mode: FileMode.append);
    } catch (_) {}

    http
        .post(
          Uri.parse('$_ingestHost$_ingestPath'),
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': _sessionId,
          },
          body: line,
        )
        .catchError((_) => http.Response('', 500));
    // #endregion

    debugPrint('[agent:$hypothesisId] $message ${data ?? {}}');
  }

  static Map<String, dynamic> navSnapshot(BuildContext context) {
    final route = ModalRoute.of(context);
    return {
      'canPop': Navigator.of(context).canPop(),
      'routeName': route?.settings.name,
      'isCurrent': route?.isCurrent,
    };
  }
}
