import 'dart:convert';
import 'dart:io';

import 'gemini.dart';
import 'parser.dart';

Uri canonicalizeUri(Uri uri) {
  // if no scheme, default to gemini
  if (!uri.hasScheme) uri = uri.replace(scheme: "gemini");
  if (!uri.hasPort) uri = uri.replace(port: 1965);

  return uri;
}

class GeminiBrowser {
  String _status = "";
  String _statusCode = "";
  List<GeminiItem> _content = [];
  List<Uri> _uriStack = [];
  int _redirectCount = 0;

  // ignore: close_sinks
  Socket? _loadSocket;

  final void Function(void Function() upd) setState;
  final void Function(Uri uri) onUriChange;

  GeminiBrowser(this.setState, this.onUriChange);

  void dispose() {
    if (_loadSocket != null) _loadSocket!.close();
  }

  Uri? getUri() {
    if (_uriStack.isNotEmpty) return _uriStack.first;
    return null;
  }

  List<GeminiItem>? getContent() => _content;
  String getStatus() => _status;
  String getStatusCode() => _statusCode;

  void open(String uriText) async {
    Uri uri = Uri.parse(uriText);
    uri = canonicalizeUri(uri);
    if (!uri.isScheme("gemini")) {
      setState(() {
        _status = "Cannot load non gemini URLs.";
      });
      return;
    }

    if (_loadSocket != null) {
      _uriStack[_uriStack.length - 1] = uri;
    } else {
      _uriStack.add(uri);
    }

    onUriChange(uri);

    _load(uri);
  }

  void refresh() async {
    Uri? uri = getUri();
    if (uri != null) {
      _load(uri);
    }
  }

  void _load(Uri uri) async {
    if (_loadSocket != null) {
      _loadSocket!.destroy();
    }

    setState(() {
      _statusCode = "";
      _status = "Connecting";
      _content = [];
    });

    _loadSocket = await SecureSocket.connect(
      uri.host,
      uri.port,
      // TODO implement TOFU
      onBadCertificate: (cert) {
        return true;
      },
    );

    setState(() {
      _status = "Sending request";
    });
    _loadSocket!.write(uri.toString() + "\r\n");

    setState(() {
      _status = "Receiving data";
    });
    List<int> buffer = [];
    await for (var b in _loadSocket!) {
      buffer.addAll(b);
    }
    _loadSocket!.close();
    _loadSocket!.destroy();
    _loadSocket = null;

    String s = utf8.decode(buffer, allowMalformed: true);
    final lines = s.split("\n");
    final statusCode = lines.removeAt(0);
    if (statusCode.startsWith("3")) {
      if (_redirectCount > 5) {
        setState(() {
          _status = "Redirect limit reached.";
        });
        return;
      }

      List<String> statusComponents = statusCode.split(RegExp(r"\s+"));
      print(statusComponents);
      String uriStr = statusComponents[1];
      Uri uri = Uri.parse(uriStr);

      _redirectCount += 1;

      _load(uri);
    }

    _redirectCount = 0;

    setState(() {
      _statusCode = statusCode;
      _status = "Rendering";
    });

    GeminiParser().parse(
      lines,
      (item) {
        setState(() {
          _content.add(item);
        });
      },
      open,
    );

    setState(() {
      _status = "Loaded.";
    });
  }

  // Return whether back action succeeded.
  bool back() {
    if (_uriStack.length <= 1) return false;
    _uriStack.removeLast();
    onUriChange(_uriStack.last);
    _load(_uriStack.last);
    return true;
  }
}
