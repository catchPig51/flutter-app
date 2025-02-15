import 'dart:ui' as ui show BoxHeightStyle;

import 'package:equatable/equatable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class HighlightText extends HookWidget {
  const HighlightText(
    this.text, {
    super.key,
    this.style,
    this.highlightTextSpans = const [],
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final List<HighlightTextSpan> highlightTextSpans;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final spans = useMemoized(
      () => buildHighlightTextSpan(text, highlightTextSpans, style),
      [text, highlightTextSpans, style],
    );
    return Text.rich(
      TextSpan(
        children: spans,
      ),
      maxLines: maxLines,
      overflow: overflow,
      textWidthBasis: TextWidthBasis.longestLine,
      textAlign: textAlign,
    );
  }
}

List<InlineSpan> buildHighlightTextSpan(
    String text, List<HighlightTextSpan> highlightTextSpans,
    [TextStyle? style]) {
  final map = Map<String, HighlightTextSpan>.fromIterable(
    highlightTextSpans.where((element) => element.text.isNotEmpty),
    key: (item) => (item as HighlightTextSpan).text.toLowerCase(),
  );
  final pattern = "(${map.keys.map(RegExp.escape).join('|')})";

  if (pattern == '()') return [TextSpan(text: text, style: style)];

  final children = <InlineSpan>[];
  text.splitMapJoin(
    RegExp(pattern, caseSensitive: false),
    onMatch: (Match match) {
      final text = match[0];
      final highlightTextSpan = map[text?.toLowerCase()];
      final mouseCursor =
          highlightTextSpan?.onTap != null ? SystemMouseCursors.click : null;
      children.add(
        TextSpan(
          mouseCursor: mouseCursor,
          text: text,
          style: style?.merge(highlightTextSpan?.style) ??
              highlightTextSpan?.style,
          recognizer: TapGestureRecognizer()..onTap = highlightTextSpan?.onTap,
        ),
      );
      return '';
    },
    onNonMatch: (text) {
      children.add(TextSpan(text: text, style: style));
      return '';
    },
  );

  return children;
}

class HighlightSelectableText extends HookWidget {
  const HighlightSelectableText(
    this.text, {
    super.key,
    this.style,
    this.highlightTextSpans = const [],
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final List<HighlightTextSpan> highlightTextSpans;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final spans = useMemoized(
      () => buildHighlightTextSpan(text, highlightTextSpans, style),
      [text, highlightTextSpans, style],
    );

    return SelectableText.rich(
      TextSpan(
        children: spans,
      ),
      maxLines: maxLines,
      textWidthBasis: TextWidthBasis.longestLine,
      toolbarOptions: const ToolbarOptions(),
      selectionHeightStyle: ui.BoxHeightStyle.includeLineSpacingMiddle,
    );
  }
}

class HighlightTextSpan extends Equatable {
  const HighlightTextSpan(
    this.text, {
    this.onTap,
    this.style,
  });

  final String text;
  final VoidCallback? onTap;
  final TextStyle? style;

  @override
  List<Object?> get props => [
        text,
        style,
      ];
}

class HighlightStarLinkText extends HookWidget {
  const HighlightStarLinkText(
    this.text, {
    super.key,
    required this.links,
    this.style,
    this.highlightStyle,
    this.onLinkClick,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final List<String> links;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final void Function(String link)? onLinkClick;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final spans = useMemoized(
      () {
        // replace ** around text with highlight text span
        var start = text.indexOf('**');
        var end = 0;
        final spans = <TextSpan>[];

        if (start == -1) {
          spans.add(TextSpan(text: text, style: style));
          return spans;
        }
        var count = 0;
        while (start != -1) {
          end = text.indexOf('**', start + 2);
          if (end == -1) {
            assert(false, 'text must be surrounded by **. $text');
            spans.add(TextSpan(text: text.substring(start), style: style));
            break;
          }

          // add text before **
          if (start > 0) {
            spans.add(TextSpan(text: text.substring(0, start), style: style));
          }

          final link = links[count];
          spans.add(
            TextSpan(
              text: text.substring(start + 2, end),
              style: style?.merge(highlightStyle),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  onLinkClick?.call(link);
                },
            ),
          );
          start = text.indexOf('**', end + 2);
          count++;
        }
        // add text after end.
        if (end + 2 < text.length) {
          spans.add(TextSpan(text: text.substring(end + 2), style: style));
        }
        return spans;
      },
      [text, highlightStyle, links],
    );
    return Text.rich(
      TextSpan(
        children: spans,
      ),
      maxLines: maxLines,
      overflow: overflow,
      style: style,
      textWidthBasis: TextWidthBasis.longestLine,
    );
  }
}
