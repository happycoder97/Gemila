import 'gemini.dart';

class GeminiParser {
  void parse(
    List<String> lines,
    void Function(GeminiItem item) itemCallback,
    void Function(String link) linkHandler,
  ) {
    GeminiItem item;
    for (final line in lines) {
      if (!(item is GeminiPre) && GeminiPre.matchOpening(line)) {
        item = GeminiPre([]);
        continue;
      }
      if (item is GeminiPre) {
        if (GeminiPre.matchClosing(line)) {
          itemCallback(item);
          item = null;
          continue;
        }
        (item as GeminiPre).lines.add(line);
        continue;
      }

      if (!(item is GeminiQuote)) {
        item = GeminiQuote.tryParse(line);
        if (item != null) {
          itemCallback(item);
          continue;
        }
      } else {
        if ((item as GeminiQuote).tryParseAndAppend(line)) {
          continue;
        }
      }

      // Note: It has to be in this order H3 -> H2 -> H1
      // Because H1 will match for H2 and H3 also.

      item = GeminiH3.tryParse(line);
      if (item != null) {
        itemCallback(item);
        continue;
      }

      item = GeminiH2.tryParse(line);
      if (item != null) {
        itemCallback(item);
        continue;
      }

      item = GeminiH1.tryParse(line);
      if (item != null) {
        itemCallback(item);
        continue;
      }

      item = GeminiListItem.tryParse(line);
      if (item != null) {
        itemCallback(item);
        continue;
      }

      item = GeminiLink.tryParse(line, linkHandler);
      if (item != null) {
        itemCallback(item);
        continue;
      }

      item = GeminiQuote.tryParse(line);
      if (item != null) {
        itemCallback(item);
        continue;
      }

      item = GeminiText.tryParse(line);
      if (item != null) {
        itemCallback(item);
        continue;
      }
    }
  }
}
