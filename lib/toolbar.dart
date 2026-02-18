import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main.dart';
import 'responsive_layout.dart';

class Toolbar extends StatefulWidget {
  final CustomTheme theme;
  final TextEditingController textController;
  final VoidCallback? handleNewFile;
  final VoidCallback? handleSave;
  final VoidCallback? handleSaveAs;
  final VoidCallback? handleShare;
  final VoidCallback? handleFileOpen;
  final String selectedFont;
  final FontWeight fontWeight;
  final double fontSize;
  final List<String> availableFonts;
  final Map<String, FontWeight> fontWeights;
  final Function(String) onFontChanged;
  final Function(FontWeight) onFontWeightChanged;
  final Function(double) onFontSizeChanged;

  const Toolbar({
    super.key,
    required this.theme,
    required this.textController,
    required this.handleNewFile,
    this.handleSave,
    this.handleSaveAs,
    this.handleShare,
    this.handleFileOpen,
    required this.selectedFont,
    required this.fontWeight,
    required this.fontSize,
    required this.availableFonts,
    required this.fontWeights,
    required this.onFontChanged,
    required this.onFontWeightChanged,
    required this.onFontSizeChanged,
  });

  @override
  State<StatefulWidget> createState() {
    return _ToolbarState();
  }
}

class _ToolbarState extends State<Toolbar> {
  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required CustomTheme theme,
  }) {
    return IconButton(
      icon: Icon(icon, color: theme.textColor, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  void _showFontDropdown(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + button.size.height,
        offset.dx + button.size.width,
        0,
      ),
      color: widget.theme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: widget.availableFonts.map((font) {
        return PopupMenuItem<String>(
          value: font,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  font,
                  style: GoogleFonts.getFont(font, color: widget.theme.textColor),
                ),
              ),
              if (widget.selectedFont == font)
                Icon(Icons.check, size: 18, color: widget.theme.accentColor),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        widget.onFontChanged(value);
      }
    });
  }

  void _showWeightDropdown(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    showMenu<FontWeight>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + button.size.height,
        offset.dx + button.size.width,
        0,
      ),
      color: widget.theme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: widget.fontWeights.entries.map((entry) {
        return PopupMenuItem<FontWeight>(
          value: entry.value,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: widget.theme.textColor,
                    fontWeight: entry.value,
                  ),
                ),
              ),
              if (widget.fontWeight == entry.value)
                Icon(Icons.check, size: 18, color: widget.theme.accentColor),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        widget.onFontWeightChanged(value);
      }
    });
  }

  String _getCurrentWeightName() {
    return widget.fontWeights.entries
        .firstWhere((e) => e.value == widget.fontWeight)
        .key;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktopOrTablet(context);

    return Container(
      alignment: Alignment.center,
      child: Row(
        children: [
          Container(
            width: 1,
            height: 24,
            color: widget.theme.secondaryTextColor.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 8),

          // Edit Actions (Cut/Copy/Paste)
          if (isDesktop) ...[
            _buildToolbarButton(
              icon: Icons.content_cut,
              tooltip: 'Cut',
              onPressed: () {
                final selection = widget.textController.selection;
                if (selection.isValid && !selection.isCollapsed) {
                  Clipboard.setData(
                    ClipboardData(
                      text: widget.textController.text.substring(
                        selection.start,
                        selection.end,
                      ),
                    ),
                  );
                  setState(() {
                    widget.textController.text = widget.textController.text
                        .replaceRange(selection.start, selection.end, '');
                  });
                }
              },
              theme: widget.theme,
            ),
            _buildToolbarButton(
              icon: Icons.content_copy,
              tooltip: 'Copy',
              onPressed: () {
                final selection = widget.textController.selection;
                if (selection.isValid && !selection.isCollapsed) {
                  Clipboard.setData(
                    ClipboardData(
                      text: widget.textController.text.substring(
                        selection.start,
                        selection.end,
                      ),
                    ),
                  );
                }
              },
              theme: widget.theme,
            ),
            _buildToolbarButton(
              icon: Icons.content_paste,
              tooltip: 'Paste',
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null) {
                  final selection = widget.textController.selection;
                  final text = widget.textController.text;
                  final newText = text.replaceRange(
                    selection.start,
                    selection.end,
                    data!.text!,
                  );
                  setState(() {
                    widget.textController.text = newText;
                    widget.textController.selection = TextSelection.collapsed(
                      offset: selection.start + data.text!.length,
                    );
                  });
                }
              },
              theme: widget.theme,
            ),
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 24,
              color: widget.theme.secondaryTextColor.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 4),
          ],

          // Font Selector
          Builder(
            builder: (context) => InkWell(
              onTap: () => _showFontDropdown(context),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.theme.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.theme.secondaryTextColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 120 : 80,
                      ),
                      child: Text(
                        widget.selectedFont,
                        style: GoogleFonts.getFont(
                          widget.selectedFont,
                          color: widget.theme.textColor,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: widget.theme.secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Font Weight Selector
          if (isDesktop)
            Builder(
              builder: (context) => InkWell(
                onTap: () => _showWeightDropdown(context),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.theme.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.theme.secondaryTextColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getCurrentWeightName(),
                        style: TextStyle(
                          color: widget.theme.textColor,
                          fontSize: 13,
                          fontWeight: widget.fontWeight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: widget.theme.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (isDesktop) const SizedBox(width: 8),

          // Font Size Controls
          if (isDesktop) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: widget.theme.backgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.theme.secondaryTextColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      if (widget.fontSize > 10) {
                        widget.onFontSizeChanged(widget.fontSize - 1);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.remove,
                        size: 16,
                        color: widget.theme.textColor,
                      ),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 30),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.fontSize.toInt()}',
                      style: TextStyle(
                        color: widget.theme.textColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (widget.fontSize < 40) {
                        widget.onFontSizeChanged(widget.fontSize + 1);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: widget.theme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: widget.theme.secondaryTextColor.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 4),
          ],

          // File Actions (Desktop only - mobile uses bottom drawer)
          if (isDesktop) ...[
            _buildToolbarButton(
              icon: Icons.note_add,
              tooltip: 'New File',
              onPressed: widget.handleNewFile ?? () {},
              theme: widget.theme,
            ),
            _buildToolbarButton(
              icon: Icons.folder_open,
              tooltip: 'Open File',
              onPressed: widget.handleFileOpen ?? () {},
              theme: widget.theme,
            ),
            _buildToolbarButton(
              icon: Icons.save,
              tooltip: 'Save',
              onPressed: widget.handleSave ?? () {},
              theme: widget.theme,
            ),
            _buildToolbarButton(
              icon: Icons.save_as,
              tooltip: 'Save As',
              onPressed: widget.handleSaveAs ?? () {},
              theme: widget.theme,
            ),
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 24,
              color: widget.theme.secondaryTextColor.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 4),
            _buildToolbarButton(
              icon: Icons.share,
              tooltip: 'Share',
              onPressed: widget.handleShare ?? () {},
              theme: widget.theme,
            ),
          ],
        ],
      ),
    );
  }
}
