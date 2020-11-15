import 'dart:convert';
import 'dart:io';

import 'gemini.dart';
import 'gemini_parser.dart';

/* WIP Refactor: 
 * Moved non rendering stuff to this class.
 * Figure out how readonly variables work in Dart and 
 * remove getters and make the fields public.
 */

class GeminiBrowser {
  String _status = "";
  String _respStatus = "";
  List<GeminiItem> _content;

  List<Uri> _uriStack = [];
  Uri _pageUri;
  int _redirectCount = 0;

  final void Function(void Function() upd) setState;
  final void Function(Uri uri) onUriChange;

  GeminiBrowser(this.setState, this.onUriChange);

  void _pushToUriStack(Uri uri) {
    if (!uri.isAbsolute) {
      uri = _pageUri.resolveUri(uri);
    }
    _uriStack.add(uri);
  }

  void _setStatus(String status) {
    setState(() {
      _status = status;
    });
  }

  Uri getUri() {
    if (_pageUri == null) return null;

    Uri uriWithoutPort = _pageUri;
    if (_pageUri.isScheme("gemini") && _pageUri.port == 1965) {
      uriWithoutPort = _pageUri.replace(port: null);
    }
    return uriWithoutPort;
  }

  List<GeminiItem> getContent() => _content;

  String getStatus() => _status;
  String getRespStatus() => _respStatus;

  void open(String uriText) async {
    Uri uri = Uri.parse(uriText);
    _pushToUriStack(uri);
    load();
  }

  void load() async {
    if (_uriStack.length < 1) {
      _setStatus("No URL to load.");
      return;
    }

    setState(() {
      _respStatus = "";
    });

    Uri uri = _uriStack.last;
    _setStatus("Connecting..");
    if (!uri.hasScheme) uri = uri.replace(scheme: "gemini");

    setState(() {
      _pageUri = uri;
      onUriChange(getUri());
    });

    if (!uri.isScheme("gemini")) {
      _setStatus("Cannot load non gemini URLs.");
      _uriStack.removeLast();
      return;
    }
    if (!uri.hasPort) uri = uri.replace(port: 1965);

    final socket = await SecureSocket.connect(
      uri.host,
      uri.port,
      // TODO implement TOFU
      onBadCertificate: (cert) {
        return true;
      },
    );

    _setStatus("Sending request..");
    socket.write(uri.toString() + "\r\n");

    _setStatus("Receiving data..");
    List<int> buffer = [];
    await for (var b in socket) {
      buffer.addAll(b);
    }

    _setStatus("Decoding utf8..");
    String s = utf8.decode(buffer, allowMalformed: true);

    setState(() {
      _content = [];
    });
    final lines = s.split("\n");

    final respStatus = lines.removeAt(0);
    if (respStatus.startsWith("3")) {
      if (_redirectCount > 5) {
        _setStatus("Redirect limit reached.");
        return;
      }
      _redirectCount += 1;
      _status = "Redirecting.. ($_redirectCount)";

      List<String> statusComponents = respStatus.split(RegExp(r"\s+"));
      print(statusComponents);
      String uriStr = statusComponents[1];
      Uri uri = Uri.parse(uriStr);

      _uriStack.removeLast();
      _pushToUriStack(uri);

      load();
      return;
    }
    _redirectCount = 0;

    setState(() {
      _respStatus = respStatus;
      _pageUri = uri;
    });

    _setStatus("Rendering..");
    GeminiParser().parse(lines, (item) => _content.add(item), open);

    _setStatus("Loaded.");
    socket.close();
  }

  // Return whether back action succeeded.
  bool back() {
    if (_uriStack.length <= 1) return false;
    _uriStack.removeLast();
    load();
    return true;
  }
}
