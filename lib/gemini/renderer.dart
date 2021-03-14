import 'package:flutter/widgets.dart';

import 'gemini.dart';

abstract class GeminiRenderer {
  Widget renderH1(GeminiH1 g);
  Widget renderH2(GeminiH2 g);
  Widget renderH3(GeminiH3 g);
  Widget renderListItem(GeminiListItem g);
  Widget renderLink(GeminiLink g);
  Widget renderText(GeminiText g);
  Widget renderPre(GeminiPre g);
  Widget renderQuote(GeminiQuote g);

  Widget render(GeminiItem g) {
    if (g is GeminiH1) {
      return renderH1(g);
    } else if (g is GeminiH2) {
      return renderH2(g);
    } else if (g is GeminiH3) {
      return renderH3(g);
    } else if (g is GeminiListItem) {
      return renderListItem(g);
    } else if (g is GeminiLink) {
      return renderLink(g);
    } else if (g is GeminiText) {
      return renderText(g);
    } else if (g is GeminiPre) {
      return renderPre(g);
    } else if (g is GeminiQuote) {
      return renderQuote(g);
    } else {
      throw "Unhandled GeminiItem";
    }
  }
}
