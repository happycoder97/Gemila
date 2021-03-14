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

class MultiOp {
  int _opIdx = 0;

  int newOp() {
    _opIdx++;
    return _opIdx;
  }

  bool isOpStale(int opIdx) {
    return _opIdx != opIdx;
  }

  void opComplete() {
    _opIdx = 0;
  }

  bool isRunning() {
    return _opIdx > 0;
  }
}

class GeminiBrowser {
  String _status = "";
  String _statusCode = "";
  List<GeminiItem> _content = [];
  List<Uri> _uriStack = [];
  int _redirectCount = 0;

  MultiOp loadOp = MultiOp();

  final void Function(void Function() upd) setState;
  final void Function(Uri uri) onUriChange;

  GeminiBrowser(this.setState, this.onUriChange);

  Uri? getUri() {
    if (_uriStack.isNotEmpty) return _uriStack.first;
    return null;
  }

  List<GeminiItem>? getContent() => _content;
  String getStatus() => _status;
  String getStatusCode() => _statusCode;

  void _addUriToStack(Uri uri) {
    if (loadOp.isRunning()) {
      _uriStack[_uriStack.length - 1] = uri;
    } else {
      _uriStack.add(uri);
    }
  }

  void open(String uriText) async {
    Uri uri = Uri.parse(uriText);
    uri = canonicalizeUri(uri);
    if (!uri.isScheme("gemini")) {
      setState(() {
        _status = "Cannot load non gemini URLs.";
      });
      return;
    }
    _addUriToStack(uri);
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
    final opIdx = loadOp.newOp();

    setState(() {
      _statusCode = "";
      _status = "Connecting";
      _content = [];
    });

    final socket = await SecureSocket.connect(
      uri.host,
      uri.port,
      // TODO implement TOFU
      onBadCertificate: (cert) {
        return true;
      },
    );

    if (loadOp.isOpStale(opIdx)) return;
    setState(() {
      _status = "Sending request";
    });
    socket.write(uri.toString() + "\r\n");

    if (loadOp.isOpStale(opIdx)) return;
    setState(() {
      _status = "Receiving data";
    });
    List<int> buffer = [];
    await for (var b in socket) {
      buffer.addAll(b);
    }
    socket.close();

    if (loadOp.isOpStale(opIdx)) return;

    String s = utf8.decode(buffer, allowMalformed: true);
    final lines = s.split("\n");
    final statusCode = lines.removeAt(0);
    if (statusCode.startsWith("3")) {
      if (_redirectCount > 5) {
        setState(() {
          _status = "Redirect limit reached.";
        });
        loadOp.opComplete();
        return;
      }

      List<String> statusComponents = statusCode.split(RegExp(r"\s+"));
      print(statusComponents);
      String uriStr = statusComponents[1];
      Uri uri = Uri.parse(uriStr);

      _redirectCount += 1;

      _load(uri);
      return;
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

    loadOp.opComplete();
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
