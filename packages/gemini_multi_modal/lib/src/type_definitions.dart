typedef EventCallback = void Function(dynamic data);

typedef StreamingLog = ({DateTime date, String type, dynamic message});

typedef ToolCall = Map<String, dynamic>;
typedef ToolCallCancellation = Map<String, dynamic>;
typedef ServerContent = Map<String, dynamic>;
typedef LiveConfig = Map<String, dynamic>;
typedef Part = Map<String, dynamic>;
typedef GenerativeContentBlob = ({String mimeType, String data});
