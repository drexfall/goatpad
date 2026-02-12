import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(GoatPadApp(prefs: prefs));
}

class GoatPadApp extends StatelessWidget {
  final SharedPreferences prefs;

  const GoatPadApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoatPad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: TextEditorScreen(prefs: prefs),
    );
  }
}

class CustomTheme {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color primaryColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Brightness brightness;

  CustomTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.primaryColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.brightness,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'backgroundColor': _colorToInt(backgroundColor),
    'surfaceColor': _colorToInt(surfaceColor),
    'primaryColor': _colorToInt(primaryColor),
    'textColor': _colorToInt(textColor),
    'secondaryTextColor': _colorToInt(secondaryTextColor),
    'accentColor': _colorToInt(accentColor),
    'brightness': brightness == Brightness.dark ? 'dark' : 'light',
  };

  static int _colorToInt(Color color) {
    return (color.a * 255).round() << 24 |
        (color.r * 255).round() << 16 |
        (color.g * 255).round() << 8 |
        (color.b * 255).round();
  }

  factory CustomTheme.fromJson(Map<String, dynamic> json) => CustomTheme(
    id: json['id'],
    name: json['name'],
    backgroundColor: Color(json['backgroundColor']),
    surfaceColor: Color(json['surfaceColor']),
    primaryColor: Color(json['primaryColor']),
    textColor: Color(json['textColor']),
    secondaryTextColor: Color(json['secondaryTextColor']),
    accentColor: Color(json['accentColor']),
    brightness: json['brightness'] == 'dark'
        ? Brightness.dark
        : Brightness.light,
  );

  static List<CustomTheme> get defaultThemes => [
    CustomTheme(
      id: 'light',
      name: 'Light',
      backgroundColor: const Color(0xFFFAFAFA),
      surfaceColor: const Color(0xFFFFFFFF),
      primaryColor: const Color(0xFF1976D2),
      textColor: const Color(0xFF212121),
      secondaryTextColor: const Color(0xFF757575),
      accentColor: const Color(0xFF2196F3),
      brightness: Brightness.light,
    ),
    CustomTheme(
      id: 'dark',
      name: 'Dark',
      backgroundColor: const Color(0xFF121212),
      surfaceColor: const Color(0xFF1E1E1E),
      primaryColor: const Color(0xFF90CAF9),
      textColor: const Color(0xFFE0E0E0),
      secondaryTextColor: const Color(0xFFB0B0B0),
      accentColor: const Color(0xFF64B5F6),
      brightness: Brightness.dark,
    ),
    CustomTheme(
      id: 'nord',
      name: 'Nord',
      backgroundColor: const Color(0xFF2E3440),
      surfaceColor: const Color(0xFF3B4252),
      primaryColor: const Color(0xFF88C0D0),
      textColor: const Color(0xFFECEFF4),
      secondaryTextColor: const Color(0xFFD8DEE9),
      accentColor: const Color(0xFF81A1C1),
      brightness: Brightness.dark,
    ),
    CustomTheme(
      id: 'monokai',
      name: 'Monokai',
      backgroundColor: const Color(0xFF272822),
      surfaceColor: const Color(0xFF1E1F1C),
      primaryColor: const Color(0xFFF92672),
      textColor: const Color(0xFFF8F8F2),
      secondaryTextColor: const Color(0xFFA6E22E),
      accentColor: const Color(0xFFE6DB74),
      brightness: Brightness.dark,
    ),
    CustomTheme(
      id: 'solarized',
      name: 'Solarized Light',
      backgroundColor: const Color(0xFFFDF6E3),
      surfaceColor: const Color(0xFFEEE8D5),
      primaryColor: const Color(0xFF268BD2),
      textColor: const Color(0xFF586E75),
      secondaryTextColor: const Color(0xFF657B83),
      accentColor: const Color(0xFF2AA198),
      brightness: Brightness.light,
    ),
    CustomTheme(
      id: 'dracula',
      name: 'Dracula',
      backgroundColor: const Color(0xFF282A36),
      surfaceColor: const Color(0xFF44475A),
      primaryColor: const Color(0xFFBD93F9),
      textColor: const Color(0xFFF8F8F2),
      secondaryTextColor: const Color(0xFF6272A4),
      accentColor: const Color(0xFFFF79C6),
      brightness: Brightness.dark,
    ),
  ];
}

class TextEditorScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const TextEditorScreen({super.key, required this.prefs});

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  final TextEditingController _textController = TextEditingController();
  List<CustomTheme> _themes = [];
  int _currentThemeIndex = 0;
  String _selectedFont = 'Roboto';
  double _fontSize = 16.0;
  FontWeight _fontWeight = FontWeight.normal;
  String? _currentFilePath;
  bool _hasUnsavedChanges = false;

  final List<String> _availableFonts = [
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
    'Raleway',
    'Merriweather',
    'Playfair Display',
    'Oswald',
    'PT Sans',
    'Inconsolata',
    'Courier Prime',
    'IBM Plex Mono',
    'Space Mono',
    'Roboto Mono',
  ];

  final Map<String, FontWeight> _fontWeights = {
    'Thin': FontWeight.w100,
    'Extra Light': FontWeight.w200,
    'Light': FontWeight.w300,
    'Normal': FontWeight.w400,
    'Medium': FontWeight.w500,
    'Semi Bold': FontWeight.w600,
    'Bold': FontWeight.w700,
    'Extra Bold': FontWeight.w800,
    'Black': FontWeight.w900,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _loadSettings() async {
    final themesJson = widget.prefs.getString('custom_themes');
    if (themesJson != null) {
      final List<dynamic> decoded = jsonDecode(themesJson);
      _themes = decoded.map((t) => CustomTheme.fromJson(t)).toList();
    }

    if (_themes.isEmpty) {
      _themes = CustomTheme.defaultThemes;
    }

    setState(() {
      _currentThemeIndex = widget.prefs.getInt('theme_index') ?? 0;
      _selectedFont = widget.prefs.getString('font') ?? 'Roboto';
      _fontSize = widget.prefs.getDouble('font_size') ?? 16.0;
      final weightIndex = widget.prefs.getInt('font_weight') ?? 3;
      _fontWeight = _fontWeights.values.elementAt(weightIndex);
    });
  }

  Future<void> _saveSettings() async {
    await widget.prefs.setInt('theme_index', _currentThemeIndex);
    await widget.prefs.setString('font', _selectedFont);
    await widget.prefs.setDouble('font_size', _fontSize);
    await widget.prefs.setInt(
      'font_weight',
      _fontWeights.values.toList().indexOf(_fontWeight),
    );

    final themesJson = jsonEncode(_themes.map((t) => t.toJson()).toList());
    await widget.prefs.setString('custom_themes', themesJson);
  }

  TextStyle _getTextStyle() {
    return GoogleFonts.getFont(
      _selectedFont,
      fontSize: _fontSize,
      fontWeight: _fontWeight,
      color: _themes[_currentThemeIndex].textColor,
      height: 1.5,
      letterSpacing: 0.2,
    );
  }

  Future<void> _openFile() async {
    if (_hasUnsavedChanges) {
      final shouldContinue = await _showUnsavedDialog();
      if (shouldContinue != true) return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      setState(() {
        _textController.text = content;
        _currentFilePath = result.files.single.path;
        _hasUnsavedChanges = false;
      });

      _showSnackBar('File opened successfully');
    }
  }

  Future<void> _saveFile() async {
    if (_currentFilePath != null) {
      final file = File(_currentFilePath!);
      await file.writeAsString(_textController.text);
      setState(() => _hasUnsavedChanges = false);
      _showSnackBar('File saved successfully');
    } else {
      await _saveFileAs();
    }
  }

  Future<void> _saveFileAs() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save file as',
      fileName: 'untitled.txt',
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (path != null) {
      final file = File(path);
      await file.writeAsString(_textController.text);

      setState(() {
        _currentFilePath = path;
        _hasUnsavedChanges = false;
      });

      _showSnackBar('File saved successfully');
    }
  }

  Future<void> _newFile() async {
    if (_hasUnsavedChanges) {
      final shouldContinue = await _showUnsavedDialog();
      if (shouldContinue != true) return;
    }

    setState(() {
      _textController.clear();
      _currentFilePath = null;
      _hasUnsavedChanges = false;
    });
  }

  Future<bool?> _showUnsavedDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to continue without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQRCode() {
    final theme = _themes[_currentThemeIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Share via QR Code',
          style: TextStyle(color: theme.textColor),
        ),
        content: SizedBox(
          width: 300,
          height: 300,
          child: _textController.text.isEmpty
              ? Center(
                  child: Text(
                    'No text to share',
                    style: TextStyle(color: theme.secondaryTextColor),
                  ),
                )
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
            child: Text('Close', style: TextStyle(color: theme.accentColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _scanQRCode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          theme: _themes[_currentThemeIndex],
          onScan: (text) {
            setState(() {
              _textController.text = text;
              _hasUnsavedChanges = true;
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
    final theme = _themes[_currentThemeIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text('Select Font', style: TextStyle(color: theme.textColor)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _availableFonts.length,
            itemBuilder: (context, index) {
              final font = _availableFonts[index];
              return ListTile(
                title: Text(
                  font,
                  style: GoogleFonts.getFont(font, color: theme.textColor),
                ),
                trailing: _selectedFont == font
                    ? Icon(Icons.check_circle, color: theme.accentColor)
                    : null,
                onTap: () {
                  setState(() => _selectedFont = font);
                  _saveSettings();
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
    final theme = _themes[_currentThemeIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Select Font Weight',
          style: TextStyle(color: theme.textColor),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _fontWeights.length,
            itemBuilder: (context, index) {
              final key = _fontWeights.keys.elementAt(index);
              return ListTile(
                title: Text(key, style: TextStyle(color: theme.textColor)),
                trailing: _fontWeight == _fontWeights[key]
                    ? Icon(Icons.check_circle, color: theme.accentColor)
                    : null,
                onTap: () {
                  setState(() => _fontWeight = _fontWeights[key]!);
                  _saveSettings();
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
    final theme = _themes[_currentThemeIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text('Select Theme', style: TextStyle(color: theme.textColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _themes.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _themes[index].backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.secondaryTextColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _themes[index].accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  _themes[index].name,
                  style: TextStyle(color: theme.textColor),
                ),
                trailing: _currentThemeIndex == index
                    ? Icon(Icons.check_circle, color: theme.accentColor)
                    : null,
                onTap: () {
                  setState(() => _currentThemeIndex = index);
                  _saveSettings();
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCreateThemeDialog();
            },
            child: Text(
              'Create Custom',
              style: TextStyle(color: theme.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateThemeDialog() {
    final theme = _themes[_currentThemeIndex];
    final nameController = TextEditingController();
    Color backgroundColor = theme.backgroundColor;
    Color surfaceColor = theme.surfaceColor;
    Color primaryColor = theme.primaryColor;
    Color textColor = theme.textColor;
    Color secondaryTextColor = theme.secondaryTextColor;
    Color accentColor = theme.accentColor;
    Brightness brightness = theme.brightness;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.surfaceColor,
          title: Text(
            'Create Custom Theme',
            style: TextStyle(color: theme.textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Theme Name',
                    labelStyle: TextStyle(color: theme.secondaryTextColor),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: theme.secondaryTextColor),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildColorPicker('Background', backgroundColor, (color) {
                  setDialogState(() => backgroundColor = color);
                }, theme),
                _buildColorPicker('Surface', surfaceColor, (color) {
                  setDialogState(() => surfaceColor = color);
                }, theme),
                _buildColorPicker('Primary', primaryColor, (color) {
                  setDialogState(() => primaryColor = color);
                }, theme),
                _buildColorPicker('Text', textColor, (color) {
                  setDialogState(() => textColor = color);
                }, theme),
                _buildColorPicker('Secondary Text', secondaryTextColor, (
                  color,
                ) {
                  setDialogState(() => secondaryTextColor = color);
                }, theme),
                _buildColorPicker('Accent', accentColor, (color) {
                  setDialogState(() => accentColor = color);
                }, theme),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newTheme = CustomTheme(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    backgroundColor: backgroundColor,
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: accentColor,
                    brightness: brightness,
                  );

                  setState(() {
                    _themes.add(newTheme);
                    _currentThemeIndex = _themes.length - 1;
                  });

                  _saveSettings();
                  Navigator.pop(context);
                  _showSnackBar('Custom theme created');
                }
              },
              child: Text('Create', style: TextStyle(color: theme.accentColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(
    String label,
    Color currentColor,
    Function(Color) onColorChanged,
    CustomTheme theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textColor)),
          GestureDetector(
            onTap: () async {
              final color = await _showColorPickerDialog(currentColor, theme);
              if (color != null) {
                onColorChanged(color);
              }
            },
            child: Container(
              width: 50,
              height: 36,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.secondaryTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Color?> _showColorPickerDialog(
    Color currentColor,
    CustomTheme theme,
  ) async {
    Color selectedColor = currentColor;

    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text('Pick a Color', style: TextStyle(color: theme.textColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                          Colors.red,
                          Colors.pink,
                          Colors.purple,
                          Colors.deepPurple,
                          Colors.indigo,
                          Colors.blue,
                          Colors.lightBlue,
                          Colors.cyan,
                          Colors.teal,
                          Colors.green,
                          Colors.lightGreen,
                          Colors.lime,
                          Colors.yellow,
                          Colors.amber,
                          Colors.orange,
                          Colors.deepOrange,
                          Colors.brown,
                          Colors.grey,
                          Colors.blueGrey,
                          Colors.black,
                          Colors.white,
                        ]
                        .map(
                          (color) => GestureDetector(
                            onTap: () {
                              Navigator.pop(context, color);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: color == selectedColor
                                      ? theme.accentColor
                                      : theme.secondaryTextColor,
                                  width: color == selectedColor ? 3 : 1,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsPanel() {
    final theme = _themes[_currentThemeIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.font_download,
                      title: 'Font Family',
                      subtitle: _selectedFont,
                      onTap: () {
                        Navigator.pop(context);
                        _showFontPicker();
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsTile(
                      icon: Icons.format_bold,
                      title: 'Font Weight',
                      subtitle: _fontWeights.entries
                          .firstWhere((e) => e.value == _fontWeight)
                          .key,
                      onTap: () {
                        Navigator.pop(context);
                        _showFontWeightPicker();
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.format_size,
                                color: theme.accentColor,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Font Size',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: theme.textColor,
                                      ),
                                    ),
                                    Text(
                                      '${_fontSize.toStringAsFixed(0)} pt',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: theme.accentColor,
                              inactiveTrackColor: theme.secondaryTextColor
                                  .withValues(alpha: 0.3),
                              thumbColor: theme.accentColor,
                              overlayColor: theme.accentColor.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            child: Slider(
                              value: _fontSize,
                              min: 10,
                              max: 40,
                              divisions: 30,
                              onChanged: (value) {
                                setState(() => _fontSize = value);
                                setModalState(() => _fontSize = value);
                                _saveSettings();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsTile(
                      icon: Icons.palette,
                      title: 'Theme',
                      subtitle: _themes[_currentThemeIndex].name,
                      onTap: () {
                        Navigator.pop(context);
                        _showThemePicker();
                      },
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required CustomTheme theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.accentColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themes[_currentThemeIndex];
    final fileName = _currentFilePath?.split('/').last ?? 'Untitled';

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'goatpad-logo.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Text(
              fileName + (_hasUnsavedChanges ? ' *' : ''),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 24,
              color: theme.secondaryTextColor.withValues(alpha: 0.3),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
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
                      final selection = _textController.selection;
                      if (selection.isValid && !selection.isCollapsed) {
                        Clipboard.setData(
                          ClipboardData(
                            text: _textController.text.substring(
                              selection.start,
                              selection.end,
                            ),
                          ),
                        );
                        setState(() {
                          _textController.text = _textController.text
                              .replaceRange(selection.start, selection.end, '');
                        });
                      }
                    },
                    theme: theme,
                  ),
                  _buildToolbarButton(
                    icon: Icons.content_copy,
                    tooltip: 'Copy',
                    onPressed: () {
                      final selection = _textController.selection;
                      if (selection.isValid && !selection.isCollapsed) {
                        Clipboard.setData(
                          ClipboardData(
                            text: _textController.text.substring(
                              selection.start,
                              selection.end,
                            ),
                          ),
                        );
                      }
                    },
                    theme: theme,
                  ),
                  _buildToolbarButton(
                    icon: Icons.content_paste,
                    tooltip: 'Paste',
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
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.secondaryTextColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 8),
                  _buildToolbarButton(
                    icon: Icons.undo,
                    tooltip: 'Undo',
                    onPressed: () {},
                    theme: theme,
                  ),
                  _buildToolbarButton(
                    icon: Icons.redo,
                    tooltip: 'Redo',
                    onPressed: () {},
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.folder_open, color: theme.textColor),
            tooltip: 'Open File',
            onPressed: _openFile,
          ),
          IconButton(
            icon: Icon(Icons.save, color: theme.textColor),
            tooltip: 'Save File',
            onPressed: _saveFile,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.textColor),
            color: theme.surfaceColor,
            onSelected: (value) {
              switch (value) {
                case 'new':
                  _newFile();
                  break;
                case 'save_as':
                  _saveFileAs();
                  break;
                case 'share':
                  _shareText();
                  break;
                case 'qr_show':
                  _showQRCode();
                  break;
                case 'qr_scan':
                  _scanQRCode();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.note_add, color: theme.textColor),
                    const SizedBox(width: 12),
                    Text('New File', style: TextStyle(color: theme.textColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'save_as',
                child: Row(
                  children: [
                    Icon(Icons.save_as, color: theme.textColor),
                    const SizedBox(width: 12),
                    Text('Save As', style: TextStyle(color: theme.textColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: theme.textColor),
                    const SizedBox(width: 12),
                    Text('Share', style: TextStyle(color: theme.textColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'qr_show',
                child: Row(
                  children: [
                    Icon(Icons.qr_code, color: theme.textColor),
                    const SizedBox(width: 12),
                    Text(
                      'Show QR Code',
                      style: TextStyle(color: theme.textColor),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'qr_scan',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: theme.textColor),
                    const SizedBox(width: 12),
                    Text(
                      'Scan QR Code',
                      style: TextStyle(color: theme.textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.settings, color: theme.textColor),
            tooltip: 'Settings',
            onPressed: _showSettingsPanel,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: theme.backgroundColor,
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _textController,
                style: _getTextStyle(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Start typing or open a file...',
                  hintStyle: _getTextStyle().copyWith(
                    color: theme.secondaryTextColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}

class QRScannerScreen extends StatefulWidget {
  final CustomTheme theme;
  final Function(String) onScan;

  const QRScannerScreen({super.key, required this.theme, required this.onScan});

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
      backgroundColor: widget.theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.theme.surfaceColor,
        title: Text(
          'Scan QR Code',
          style: TextStyle(color: widget.theme.textColor),
        ),
        iconTheme: IconThemeData(color: widget.theme.textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on, color: widget.theme.textColor),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: Icon(Icons.flip_camera_ios, color: widget.theme.textColor),
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
