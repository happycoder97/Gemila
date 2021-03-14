import 'package:flutter/material.dart';
import 'gemini_browser.dart';

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
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

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
  final _urlController =
      TextEditingController(text: "gemini://gemini.circumlunar.space/");
  late GeminiBrowser _browser;

  late FocusNode _uriFieldFocusNode;
  bool _isUriFieldFocused = false;

  @override
  void initState() {
    super.initState();
    _browser = GeminiBrowser(setState, _setUri);
    _uriFieldFocusNode = FocusNode();
    _uriFieldFocusNode.addListener(() {
      setState(() {
        _isUriFieldFocused = _uriFieldFocusNode.hasFocus;
        _restoreUri();
      });
    });
  }

  void _restoreUri() {
    if (!_isUriFieldFocused &&
        _urlController.text.isEmpty &&
        _browser.getUri() != null) {
      _urlController.text = _browser.getUri().toString();
    }
  }

  void _setUri(Uri uri) {
    _urlController.text = uri.toString();
  }

  Future<bool> _handleBackButton() async {
    return !_browser.back();
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
    final _content = _browser.getContent();
    if (_content == null) {
      geminiTexts = [Text("No page loaded")];
    } else {
      geminiTexts = _content
          .map((geminiItem) => geminiItem.toWidget())
          .toList(growable: false);
    }

    bool refreshOrGo = _browser.getUri().toString() == _urlController.text;

    final urlBar = Padding(
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
                        icon: Icon(
                            refreshOrGo ? Icons.refresh : Icons.arrow_forward),
                        onPressed: () {
                          _uriFieldFocusNode.unfocus();
                          _uriFieldFocusNode.canRequestFocus = false;
                          if (refreshOrGo) {
                            _browser.refresh();
                          } else {
                            _browser.open(_urlController.text);
                          }
                          Future.delayed(
                            Duration(milliseconds: 100),
                            () {
                              _uriFieldFocusNode.canRequestFocus = true;
                            },
                          );
                        },
                      ),
              ),
              onSubmitted: _browser.open,
              focusNode: _uriFieldFocusNode,
            ),
          ),
        ],
      ),
    );

    final _status = _browser.getStatus();
    final _statusCode = _browser.getStatusCode();
    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              urlBar,
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
                  children: [Text('$_status'), Text('$_statusCode')],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
