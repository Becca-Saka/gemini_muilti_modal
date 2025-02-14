import 'type_definitions.dart';

class EventEmitter {
  final Map<String, List<EventCallback>> _listeners = {};

  void on(String event, EventCallback callback) {
    _listeners[event] ??= [];
    _listeners[event]!.add(callback);
  }

  void off(String event, EventCallback callback) {
    if (_listeners.containsKey(event)) {
      _listeners[event]!.remove(callback);
      if (_listeners[event]!.isEmpty) {
        _listeners.remove(event);
      }
    }
  }

  void emit(String event, [dynamic data]) {
    if (_listeners.containsKey(event)) {
      for (var callback in _listeners[event]!) {
        callback(data);
      }
    }
  }
}
