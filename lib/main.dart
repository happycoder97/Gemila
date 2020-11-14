import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'gemini.dart';
import 'gemini_parser.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.green,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _status = "";
  String _respStatus = "";
  List<GeminiItem> _content;
  final _urlController =
      TextEditingController(text: "gemini://gemini.circumlunar.space/");
  List<Uri> _uriStack = [];
  Uri _pageUri;
  int _redirectCount = 0;
  FocusNode _uriFieldFocusNode;
  bool _isUriFieldFocused = false;

  void _pushToUriStack(Uri uri) {
    if (!uri.isAbsolute) {
      uri = _pageUri.resolveUri(uri);
    }
    _uriStack.add(uri);
  }

  void _handleLink(String link) async {
    setState(() {
      Uri uri = Uri.parse(link);
      _pushToUriStack(uri);
    });
    _load();
  }

  void _setStatus(String status) {
    setState(() {
      _status = status;
    });
  }

  void _go(uriText) async {
    Uri uri = Uri.parse(uriText);
    _pushToUriStack(uri);
    _load();
  }

  void _load() async {
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
      Uri uriWithoutPort = uri;
      if (uri.isScheme("gemini") && uri.port == 1965) {
        uriWithoutPort = uri.replace(port: null);
      }
      _urlController.text = uriWithoutPort.toString();
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

      _load();
      return;
    }
    _redirectCount = 0;

    setState(() {
      _respStatus = respStatus;
      _pageUri = uri;
    });

    _setStatus("Rendering..");
    GeminiParser().parse(lines, (item) => _content.add(item), _handleLink);

    _setStatus("Loaded.");
    socket.close();
  }

  Future<bool> _handleBackButton() async {
    if (_uriStack.length <= 1) return true;
    _uriStack.removeLast();
    _load();
    return false;
  }

  @override
  void initState() {
    super.initState();
    _uriFieldFocusNode = FocusNode();
    _uriFieldFocusNode.addListener(() {
      setState(() {
        _isUriFieldFocused = _uriFieldFocusNode.hasFocus;
        if (!_isUriFieldFocused &&
            _urlController.text.isEmpty &&
            _pageUri != null) {
          _urlController.text = _pageUri.toString();
        }
      });
    });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _uriFieldFocusNode.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    List<Widget> geminiTexts;
    if (_content == null) {
      geminiTexts = [Text("No page loaded")];
    } else {
      geminiTexts = _content
          .map((geminiItem) => geminiItem.toWidget())
          .toList(growable: false);
    }

    bool refreshOrGo =
        _pageUri != null && _pageUri.toString() == _urlController.text;

    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(5),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.go,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.fromLTRB(10, 12, 10, 12),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          fillColor: Colors.grey[300],
                          filled: true,
                          suffixIcon: _isUriFieldFocused
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () => setState(() {
                                    _urlController.clear();
                                  }),
                                )
                              : IconButton(
                                  icon: Icon(refreshOrGo
                                      ? Icons.refresh
                                      : Icons.arrow_forward),
                                  onPressed: () {
                                    _uriFieldFocusNode.unfocus();
                                    _uriFieldFocusNode.canRequestFocus = false;
                                    if (refreshOrGo) {
                                      _load();
                                    } else {
                                      _go(_urlController.text);
                                    }

                                    Future.delayed(
                                      Duration(milliseconds: 100),
                                      () {
                                        _uriFieldFocusNode.canRequestFocus =
                                            true;
                                      },
                                    );
                                  },
                                ),
                        ),
                        onSubmitted: _go,
                        focusNode: _uriFieldFocusNode,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // _urlController.text += "1";
                    FocusScopeNode currentFocus = FocusScope.of(context);
                    if (!currentFocus.hasPrimaryFocus) {
                      currentFocus.unfocus();
                    }
                  },
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: geminiTexts,
                      ),
                    ),
                    scrollDirection: Axis.vertical,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('$_status'), Text('$_respStatus')],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
