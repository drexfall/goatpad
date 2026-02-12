import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const GoatPadApp());
}

class GoatPadApp extends StatelessWidget {
  const GoatPadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'GoatPad',
      debugShowCheckedModeBanner: false,
      home: TextEditorScreen(),
    );
  }
}

class AppTheme {
  final String name;
  final ThemeData themeData;

  AppTheme({required this.name, required this.themeData});

  static List<AppTheme> get themes => [
        AppTheme(
          name: 'Light',
          themeData: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            primaryColor: const Color(0xFF2196F3),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2196F3),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardColor: const Color(0xFFF5F5F5),
            iconTheme: const IconThemeData(color: Color(0xFF424242)),
          ),
        ),
        AppTheme(
          name: 'Dark',
          themeData: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            primaryColor: const Color(0xFF1E88E5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardColor: const Color(0xFF1E1E1E),
            iconTheme: const IconThemeData(color: Colors.white70),
          ),
        ),
        AppTheme(
          name: 'Nord',
          themeData: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF2E3440),
            primaryColor: const Color(0xFF88C0D0),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF3B4252),
              foregroundColor: Color(0xFFECEFF4),
              elevation: 0,
            ),
            cardColor: const Color(0xFF3B4252),
            iconTheme: const IconThemeData(color: Color(0xFFD8DEE9)),
          ),
        ),
        AppTheme(
          name: 'Monokai',
          themeData: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF272822),
            primaryColor: const Color(0xFFF92672),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1F1C),
              foregroundColor: Color(0xFFF8F8F2),
              elevation: 0,
            ),
            cardColor: const Color(0xFF1E1F1C),
            iconTheme: const IconThemeData(color: Color(0xFFF8F8F2)),
          ),
        ),
        AppTheme(
          name: 'Solarized',
          themeData: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFDF6E3),
            primaryColor: const Color(0xFF268BD2),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFEEE8D5),
              foregroundColor: Color(0xFF657B83),
              elevation: 0,
            ),
            cardColor: const Color(0xFFEEE8D5),
            iconTheme: const IconThemeData(color: Color(0xFF657B83)),
          ),
        ),
      ];
}

class TextEditorScreen extends StatefulWidget {
  const TextEditorScreen({super.key});

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  final TextEditingController _textController = TextEditingController();
  int _currentThemeIndex = 0;
  String _selectedFont = 'Roboto';
  double _fontSize = 16.0;
  FontWeight _fontWeight = FontWeight.normal;

  final List<String> _fontOptions = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Poppins',
    'Ubuntu',
    'Noto Sans',
    'Source Code Pro',
    'Fira Code',
    'JetBrains Mono',
  ];

  final Map<String, FontWeight> _fontWeights = {
    'Light': FontWeight.w300,
    'Normal': FontWeight.w400,
    'Medium': FontWeight.w500,
    'Semi-Bold': FontWeight.w600,
    'Bold': FontWeight.w700,
  };

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  TextStyle _getTextStyle() {
    return GoogleFonts.getFont(
      _selectedFont,
      fontSize: _fontSize,
      fontWeight: _fontWeight,
      color: AppTheme.themes[_currentThemeIndex].themeData.brightness == Brightness.light
          ? Colors.black87
          : Colors.white,
    );
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share via QR Code'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: _textController.text.isEmpty
              ? const Center(child: Text('No text to share'))
              : QrImageView(
                  data: _textController.text,
                  version: QrVersions.auto,
                  size: 280,
                  backgroundColor: Colors.white,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _scanQRCode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onScan: (text) {
            setState(() {
              _textController.text = text;
            });
          },
        ),
      ),
    );
  }

  void _shareText() {
    if (_textController.text.isNotEmpty) {
      Share.share(_textController.text);
    }
  }

  void _showFontPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Font'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _fontOptions.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  _fontOptions[index],
                  style: GoogleFonts.getFont(_fontOptions[index]),
                ),
                trailing: _selectedFont == _fontOptions[index]
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedFont = _fontOptions[index];
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFontWeightPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Font Weight'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _fontWeights.length,
            itemBuilder: (context, index) {
              String key = _fontWeights.keys.elementAt(index);
              return ListTile(
                title: Text(key),
                trailing: _fontWeight == _fontWeights[key]
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() {
                    _fontWeight = _fontWeights[key]!;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showThemePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppTheme.themes.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(AppTheme.themes[index].name),
                trailing: _currentThemeIndex == index
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() {
                    _currentThemeIndex = index;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.font_download),
                    title: const Text('Font Family'),
                    subtitle: Text(_selectedFont),
                    onTap: () {
                      Navigator.pop(context);
                      _showFontPicker();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.format_bold),
                    title: const Text('Font Weight'),
                    subtitle: Text(_fontWeights.entries
                        .firstWhere((e) => e.value == _fontWeight)
                        .key),
                    onTap: () {
                      Navigator.pop(context);
                      _showFontWeightPicker();
                    },
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.format_size),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Font Size'),
                                  Text(
                                    '${_fontSize.toStringAsFixed(0)} pt',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _fontSize,
                          min: 10,
                          max: 40,
                          divisions: 30,
                          label: _fontSize.toStringAsFixed(0),
                          onChanged: (value) {
                            setState(() {
                              _fontSize = value;
                            });
                            setModalState(() {
                              _fontSize = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Theme'),
                    subtitle: Text(AppTheme.themes[_currentThemeIndex].name),
                    onTap: () {
                      Navigator.pop(context);
                      _showThemePicker();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.themes[_currentThemeIndex].themeData;

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GoatPad'),
          actions: [
            IconButton(
              icon: const Icon(Icons.content_cut),
              onPressed: () {
                final selection = _textController.selection;
                if (selection.isValid && !selection.isCollapsed) {
                  Clipboard.setData(ClipboardData(
                    text: _textController.text.substring(
                      selection.start,
                      selection.end,
                    ),
                  ));
                  setState(() {
                    _textController.text = _textController.text.replaceRange(
                      selection.start,
                      selection.end,
                      '',
                    );
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: () {
                final selection = _textController.selection;
                if (selection.isValid && !selection.isCollapsed) {
                  Clipboard.setData(ClipboardData(
                    text: _textController.text.substring(
                      selection.start,
                      selection.end,
                    ),
                  ));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.content_paste),
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null) {
                  final selection = _textController.selection;
                  final text = _textController.text;
                  final newText = text.replaceRange(
                    selection.start,
                    selection.end,
                    data!.text!,
                  );
                  setState(() {
                    _textController.text = newText;
                    _textController.selection = TextSelection.collapsed(
                      offset: selection.start + data.text!.length,
                    );
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareText,
            ),
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: _showQRCode,
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scanQRCode,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsPanel,
            ),
          ],
        ),
        body: Container(
          color: theme.scaffoldBackgroundColor,
          child: TextField(
            controller: _textController,
            style: _getTextStyle(),
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              hintText: 'Start typing...',
              hintStyle: _getTextStyle().copyWith(
                color: theme.brightness == Brightness.light
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  final Function(String) onScan;

  const QRScannerScreen({super.key, required this.onScan});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              widget.onScan(barcode.rawValue!);
              Navigator.pop(context);
              return;
            }
          }
        },
      ),
    );
  }
}
