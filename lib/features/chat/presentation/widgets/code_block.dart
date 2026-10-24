import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Custom `pre` builder: monospace card with soft-wrapped long lines.
///
/// Fenced blocks produced by models sometimes keep their fence markers
/// (indented or nested fences the parser treats as plain code) - those
/// stray fences are stripped here.
class CodeBlockBuilder extends MarkdownElementBuilder {
  CodeBlockBuilder();

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final theme = Theme.of(context);
    final code = _stripStrayFences(_textOf(element));
    if (code.trim().isEmpty) return null;
    final baseStyle = (preferredStyle ?? theme.textTheme.bodySmall)?.copyWith(
      fontFamily: 'monospace',
      height: 1.45,
    );
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(code, style: baseStyle, softWrap: true),
      ),
    );
  }

  static String _textOf(md.Node node) {
    if (node is md.Text) return node.text;
    if (node is md.Element) {
      final buffer = StringBuffer();
      for (final child in node.children ?? const <md.Node>[]) {
        buffer.write(_textOf(child));
      }
      return buffer.toString();
    }
    return '';
  }

  static String _stripStrayFences(String raw) {
    var text = raw.replaceAll('\r\n', '\n');
    if (text.endsWith('\n')) {
      text = text.substring(0, text.length - 1);
    }
    final lines = text.split('\n');
    final fence = RegExp(r'^\s*(`{3,}|~{3,})');
    while (lines.isNotEmpty && fence.hasMatch(lines.first)) {
      lines.removeAt(0);
    }
    while (lines.isNotEmpty && fence.hasMatch(lines.last)) {
      lines.removeLast();
    }
    return lines.join('\n');
  }
}
