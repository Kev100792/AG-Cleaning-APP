import 'package:flutter/material.dart';

Future<T?> showSlideOver<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  double width = 920,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    barrierDismissible: true,
    barrierLabel: 'Fermer',
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, __, ___) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      final panel = Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: width,
            height: MediaQuery.of(ctx).size.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    ctx,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  blurRadius: 32,
                  offset: const Offset(-16, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                    child: Row(
                      children: [
                        if (title != null)
                          Text(
                            title,
                            style: Theme.of(ctx).textTheme.titleLarge,
                          ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Fermer',
                          onPressed: () => Navigator.of(ctx).maybePop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Body
                  Expanded(child: builder(ctx)),
                ],
              ),
            ),
          ),
        ),
      );

      return Stack(
        children: [
          // Fade du backdrop
          Opacity(opacity: curved.value, child: const SizedBox.shrink()),
          // Slide du panel
          Transform.translate(
            offset: Offset((1 - curved.value) * width, 0),
            child: panel,
          ),
        ],
      );
    },
  );
}
