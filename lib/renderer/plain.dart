import 'dart:async';

import 'package:Gemila/gemini/gemini.dart';
import 'package:Gemila/gemini/renderer.dart';
import 'package:flutter/material.dart';

class PlainRenderer extends GeminiRenderer {
  @override
  Widget renderH1(GeminiH1 g) {
    return Text(
      g.value,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  @override
  Widget renderH2(GeminiH2 g) {
    return Text(
      g.value,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  @override
  Widget renderH3(GeminiH3 g) {
    return Text(
      g.value,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  @override
  Widget renderLink(GeminiLink g) {
    return GeminiLinkWidget(link: g.link, text: g.text, handler: g.handler);
  }

  @override
  Widget renderListItem(GeminiListItem g) {
    return Text(
      "• " + g.value,
      style: TextStyle(color: Colors.black),
    );
  }

  @override
  Widget renderPre(GeminiPre g) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: g.lines
            .map(
              (line) => Text(
                line,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "monospace",
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget renderQuote(GeminiQuote g) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            g.value,
            style: TextStyle(
              color: Colors.black,
              // backgroundColor: Colors.grey[200],
            ),
          ),
        ),
        decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border(left: BorderSide(color: Colors.black87, width: 2))),
      ),
    );
  }

  @override
  Widget renderText(GeminiText g) {
    return Text(
      g.value,
      style: TextStyle(color: Colors.black),
    );
  }
}

class GeminiLinkWidget extends StatefulWidget {
  final String link;
  final String text;
  final void Function(String) handler;

  const GeminiLinkWidget(
      {Key? key, required this.link, required this.text, required this.handler})
      : super(key: key);

  @override
  _GeminiLinkWidgetState createState() => _GeminiLinkWidgetState();
}

class _GeminiLinkWidgetState extends State<GeminiLinkWidget> {
  bool _isTapping = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isTapping = true;
        });
        widget.handler(widget.link);
        Timer(
          new Duration(milliseconds: 200),
          () => setState(() {
            _isTapping = false;
          }),
        );
      },
      onTapDown: (_details) => setState(() {
        _isTapping = true;
      }),
      onTapUp: (_details) => setState(() {
        _isTapping = false;
      }),
      onTapCancel: () => setState(() {
        _isTapping = false;
      }),
      child: Container(
        decoration: BoxDecoration(
          color: _isTapping ? Colors.grey[200] : Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child: RichText(
            text: TextSpan(
              text: widget.text,
              style: TextStyle(
                  color: Colors.black, decoration: TextDecoration.underline),
              children: [
                TextSpan(
                  text: "\n" + widget.link,
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
