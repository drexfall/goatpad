import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';

class Toolbar extends StatefulWidget {
  final CustomTheme theme;
  final TextEditingController textController;
  final VoidCallback? handleNewFile;
  final VoidCallback? handleSave;
  final VoidCallback? handleSaveAs;
  final VoidCallback? handleShare;
  final VoidCallback? handleQR;
  final VoidCallback? handleQRScan;
  final VoidCallback? handleFileOpen;

  const Toolbar(
      {super.key,
      required this.theme,
      required this.textController,
      required this.handleNewFile,
      this.handleSave,
      this.handleSaveAs,
      this.handleShare,
      this.handleQR,
      this.handleQRScan,
      this.handleFileOpen});

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
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Row(
        children: [
          Image.asset(
            'goatpad-logo.png',
            height: 32,
            width: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 24,
            color: widget.theme.secondaryTextColor.withValues(alpha: 0.3),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.theme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
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
                        widget.textController.selection =
                            TextSelection.collapsed(
                          offset: selection.start + data.text!.length,
                        );
                      });
                    }
                  },
                  theme: widget.theme,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 24,
                  color: widget.theme.secondaryTextColor.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                _buildToolbarButton(
                  icon: Icons.undo,
                  tooltip: 'Undo',
                  onPressed: () {},
                  theme: widget.theme,
                ),
                _buildToolbarButton(
                  icon: Icons.redo,
                  tooltip: 'Redo',
                  onPressed: () {},
                  theme: widget.theme,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.note_add, color: widget.theme.textColor),
            tooltip: 'New File',
            onPressed: widget.handleNewFile,
          ),
          IconButton(
            icon: Icon(Icons.file_open, color: widget.theme.textColor),
            tooltip: 'Save File',
            onPressed: widget.handleFileOpen,
          ),
          IconButton(
            icon: Icon(Icons.save, color: widget.theme.textColor),
            tooltip: 'Save File',
            onPressed: widget.handleSave,
          ),
          IconButton(
            icon: Icon(Icons.save_as, color: widget.theme.textColor),
            tooltip: 'Save File',
            onPressed: widget.handleSaveAs,
          ),
          IconButton(
            icon: Icon(Icons.share, color: widget.theme.textColor),
            tooltip: 'Share File',
            onPressed: widget.handleShare,
          ),
          IconButton(
            icon: Icon(Icons.qr_code, color: widget.theme.textColor),
            tooltip: 'Save File',
            onPressed: widget.handleQR,
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: widget.theme.textColor),
            tooltip: 'Save File',
            onPressed: widget.handleQRScan,
          )
        ],
      ),
    );
  }
}
