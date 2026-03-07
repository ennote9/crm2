// Shared SKU link: monochrome enterprise style, opens Product Details on tap.

import 'package:flutter/material.dart';

import '../../demo_data/demo_data.dart';
import '../../theme/tokens.dart';
import 'product_details_page.dart';

/// Single interactive SKU text that opens Product Details. Use wherever SKU should act as a link.
/// Style: neutral text (textPrimary), normal weight, no underline; soft hover background and thin border.
/// Hover does not change size (border space reserved; padding constant).
class SkuLinkText extends StatefulWidget {
  const SkuLinkText({
    super.key,
    required this.sku,
    this.label,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.alignment = Alignment.centerLeft,
  });

  final String sku;
  /// If set, shown instead of [sku] (e.g. product name).
  final String? label;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;
  final AlignmentGeometry alignment;

  @override
  State<SkuLinkText> createState() => _SkuLinkTextState();
}

class _SkuLinkTextState extends State<SkuLinkText> {
  bool _hover = false;

  void _onTap() {
    final p = demoRepository.getProductBySku(widget.sku);
    if (p != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailsPage(payload: ProductDetailsPayload(productId: p.productId, sku: p.sku)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final colors = tokens.colors;
    final baseStyle = widget.style ?? theme.textTheme.bodyMedium ?? const TextStyle();
    final textStyle = baseStyle.copyWith(
      color: colors.textPrimary,
      fontWeight: FontWeight.normal,
      decoration: TextDecoration.none,
      decorationColor: null,
      decorationThickness: null,
    );
    final text = widget.label ?? widget.sku;
    final radius = tokens.radius.xs;
    const borderWidth = 1.0;
    // Reserve border space always so hover does not change layout.
    final borderColor = _hover ? colors.border.withValues(alpha: 0.6) : Colors.transparent;

    final linkContent = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hover ? colors.hoverBg : null,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onTap,
            hoverColor: Colors.transparent,
            highlightColor: colors.hoverBg.withValues(alpha: 0.25),
            splashColor: Colors.transparent,
            focusColor: colors.focusRing.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(radius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Align(
                alignment: widget.alignment,
                child: Text(
                  text,
                  style: textStyle,
                  maxLines: widget.maxLines,
                  overflow: widget.overflow,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.maxWidth.isFinite && constraints.maxHeight.isFinite;
        if (bounded && constraints.maxWidth > 0 && constraints.maxHeight > 0) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: linkContent,
          );
        }
        return linkContent;
      },
    );
  }
}
