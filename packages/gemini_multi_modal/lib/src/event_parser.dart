import 'dart:async';
import 'dart:typed_data';

import 'package:universal_html/html.dart' as html;

Future<Uint8List> parseMessage(dynamic message) async {
  if (identical(0, 0.0)) {
    if (message is html.Blob) {
      final completer = Completer<Uint8List>();
      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) {
        if (reader.result is ByteBuffer) {
          final buffer = reader.result as ByteBuffer;
          completer.complete(buffer.asUint8List());
        } else if (reader.result is Uint8List) {
          completer.complete(reader.result as Uint8List);
        } else {
          completer.completeError(
              'Unexpected result type: ${reader.result.runtimeType}');
        }
      });

      reader.onError.listen((e) {
        completer.completeError(e);
      });

      reader.readAsArrayBuffer(message);
      return completer.future;
    }
  }

  return Uint8List.fromList(List<int>.from(message));
}
