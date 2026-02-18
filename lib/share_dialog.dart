import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'main.dart';

class ShareDialog extends StatelessWidget {
  final CustomTheme theme;
  final String text;
  final VoidCallback onScanQR;

  const ShareDialog({
    super.key,
    required this.theme,
    required this.text,
    required this.onScanQR,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = text.isEmpty;
    final isTextTooLong = text.length > 2953; // QR code max character limit

    return Dialog(
      backgroundColor: theme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.secondaryTextColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // QR Code Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (isEmpty)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: theme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.text_fields,
                              size: 48,
                              color: theme.secondaryTextColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No text to share',
                              style: TextStyle(color: theme.secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (isTextTooLong)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: theme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 48,
                              color: Colors.amber,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Text too long for QR',
                              style: TextStyle(color: theme.secondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Use Share button instead',
                              style: TextStyle(
                                color: theme.secondaryTextColor,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: text,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    isEmpty
                        ? 'Start typing to generate QR code'
                        : isTextTooLong
                            ? '${text.length} characters (max 2953 for QR)'
                            : 'Scan to receive text',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    icon: Icons.share,
                    label: 'Share',
                    onTap: isEmpty
                        ? null
                        : () {
                            Navigator.pop(context);
                            Share.share(text);
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    icon: Icons.copy,
                    label: 'Copy',
                    onTap: isEmpty
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: text));
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Scan QR Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onScanQR();
                },
                icon: Icon(Icons.qr_code_scanner, color: theme.accentColor),
                label: Text(
                  'Scan QR Code',
                  style: TextStyle(color: theme.accentColor),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: theme.accentColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return Material(
      color: isEnabled ? theme.accentColor : theme.secondaryTextColor.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isEnabled ? Colors.white : theme.secondaryTextColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isEnabled ? Colors.white : theme.secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

