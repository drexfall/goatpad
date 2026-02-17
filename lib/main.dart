import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:goatpad/toolbar.dart';
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
        brightness:
            json['brightness'] == 'dark' ? Brightness.dark : Brightness.light,
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

class EditorTab {
  final String id;
  final TextEditingController controller;
  String? filePath;
  bool hasUnsavedChanges;

  EditorTab({
    required this.id,
    required this.controller,
    this.filePath,
    this.hasUnsavedChanges = false,
  });

  String get fileName => filePath?.split('/').last ?? 'Untitled';
}

class TextEditorScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const TextEditorScreen({super.key, required this.prefs});

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  List<EditorTab> _tabs = [];
  int _currentTabIndex = 0;
  List<CustomTheme> _themes = [];
  int _currentThemeIndex = 0;
  String _selectedFont = 'Roboto';
  double _fontSize = 16.0;
  FontWeight _fontWeight = FontWeight.normal;

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
    // Create initial empty tab
    _createNewTab();
  }

  @override
  void dispose() {
    for (var tab in _tabs) {
      tab.controller.dispose();
    }
    super.dispose();
  }

  EditorTab get _currentTab => _tabs[_currentTabIndex];

  void _createNewTab({String? filePath, String? content}) {
    final controller = TextEditingController(text: content ?? '');

    final tab = EditorTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      controller: controller,
      filePath: filePath,
      hasUnsavedChanges: false,
    );

    setState(() {
      _tabs.add(tab);
      _currentTabIndex = _tabs.length - 1;
    });

    // Add listener after adding tab to list
    controller.addListener(() {
      final tabIndex = _tabs.indexWhere((t) => t.id == tab.id);
      if (tabIndex != -1) {
        _onTextChanged(tabIndex);
      }
    });
  }

  void _closeTab(int index) async {
    if (_tabs[index].hasUnsavedChanges) {
      final shouldClose = await _showUnsavedDialog();
      if (shouldClose != true) return;
    }

    setState(() {
      _tabs[index].controller.dispose();
      _tabs.removeAt(index);

      if (_tabs.isEmpty) {
        _createNewTab();
      } else if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      }
    });
  }

  void _switchTab(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  void _onTextChanged(int tabIndex) {
    if (tabIndex < _tabs.length && !_tabs[tabIndex].hasUnsavedChanges) {
      setState(() => _tabs[tabIndex].hasUnsavedChanges = true);
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;

      // Check if file is already open in a tab
      final existingTabIndex =
          _tabs.indexWhere((tab) => tab.filePath == filePath);
      if (existingTabIndex != -1) {
        setState(() {
          _currentTabIndex = existingTabIndex;
        });
        _showSnackBar('File already open');
        return;
      }

      final file = File(filePath);
      final content = await file.readAsString();

      _createNewTab(filePath: filePath, content: content);
      _showSnackBar('File opened successfully');
    }
  }

  Future<void> _saveFile() async {
    if (_currentTab.filePath != null) {
      final file = File(_currentTab.filePath!);
      await file.writeAsString(_currentTab.controller.text);
      setState(() => _currentTab.hasUnsavedChanges = false);
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
      await file.writeAsString(_currentTab.controller.text);

      setState(() {
        _currentTab.filePath = path;
        _currentTab.hasUnsavedChanges = false;
      });

      _showSnackBar('File saved successfully');
    }
  }

  Future<void> _newFile() async {
    _createNewTab();
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
          child: _currentTab.controller.text.isEmpty
              ? Center(
                  child: Text(
                    'No text to share',
                    style: TextStyle(color: theme.secondaryTextColor),
                  ),
                )
              : QrImageView(
                  data: _currentTab.controller.text,
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
              _currentTab.controller.text = text;
              _currentTab.hasUnsavedChanges = true;
            });
          },
        ),
      ),
    );
  }

  void _shareText() {
    if (_currentTab.controller.text.isNotEmpty) {
      Share.share(_currentTab.controller.text);
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
                children: [
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    if (isWideScreen) {
      // Show as a side panel on wide screens
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SettingsPanelScreen(
            theme: theme,
            themes: _themes,
            currentThemeIndex: _currentThemeIndex,
            selectedFont: _selectedFont,
            fontSize: _fontSize,
            fontWeight: _fontWeight,
            fontWeights: _fontWeights,
            availableFonts: _availableFonts,
            onThemeChanged: (index) {
              setState(() => _currentThemeIndex = index);
              _saveSettings();
            },
            onFontChanged: (font) {
              setState(() => _selectedFont = font);
              _saveSettings();
            },
            onFontWeightChanged: (weight) {
              setState(() => _fontWeight = weight);
              _saveSettings();
            },
            onFontSizeChanged: (size) {
              setState(() => _fontSize = size);
              _saveSettings();
            },
            onThemeCreated: (newTheme) {
              setState(() {
                _themes.add(newTheme);
                _currentThemeIndex = _themes.length - 1;
              });
              _saveSettings();
            },
            onShowThemePicker: _showThemePicker,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    } else {
      // Show as bottom sheet on small screens
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        elevation: 0,
        toolbarHeight: 56,
        title: Toolbar(
          theme: theme,
          textController: _currentTab.controller,
          handleNewFile: _newFile,
          handleFileOpen: _openFile,
          handleQR: _showQRCode,
          handleQRScan: _scanQRCode,
          handleSave: _saveFile,
          handleSaveAs: _saveFileAs,
          handleShare: _shareText,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: theme.textColor),
            tooltip: 'Settings',
            onPressed: _showSettingsPanel,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            height: 48,
            color: theme.surfaceColor,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final isSelected = index == _currentTabIndex;

                return Tooltip(
                  message: tab.filePath ?? 'Untitled',
                  child: InkWell(
                    onTap: () => _switchTab(index),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 120,
                        maxWidth: 200,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.backgroundColor
                            : theme.surfaceColor,
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected
                                ? theme.accentColor
                                : Colors.transparent,
                            width: 2,
                          ),
                          right: BorderSide(
                            color:
                                theme.secondaryTextColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              tab.fileName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? theme.textColor
                                    : theme.secondaryTextColor,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (tab.hasUnsavedChanges)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _closeTab(index),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Editor
          Expanded(
            child: Container(
              color: theme.backgroundColor,
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _currentTab.controller,
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
}

class SettingsPanelScreen extends StatefulWidget {
  final CustomTheme theme;
  final List<CustomTheme> themes;
  final int currentThemeIndex;
  final String selectedFont;
  final double fontSize;
  final FontWeight fontWeight;
  final Map<String, FontWeight> fontWeights;
  final List<String> availableFonts;
  final Function(int) onThemeChanged;
  final Function(String) onFontChanged;
  final Function(FontWeight) onFontWeightChanged;
  final Function(double) onFontSizeChanged;
  final Function(CustomTheme) onThemeCreated;
  final VoidCallback onShowThemePicker;

  const SettingsPanelScreen({
    super.key,
    required this.theme,
    required this.themes,
    required this.currentThemeIndex,
    required this.selectedFont,
    required this.fontSize,
    required this.fontWeight,
    required this.fontWeights,
    required this.availableFonts,
    required this.onThemeChanged,
    required this.onFontChanged,
    required this.onFontWeightChanged,
    required this.onFontSizeChanged,
    required this.onThemeCreated,
    required this.onShowThemePicker,
  });

  @override
  State<SettingsPanelScreen> createState() => _SettingsPanelScreenState();
}

class _SettingsPanelScreenState extends State<SettingsPanelScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: widget.theme.backgroundColor,
        appBar: AppBar(
          backgroundColor: widget.theme.surfaceColor,
          title: Text(
            'Settings',
            style: TextStyle(color: widget.theme.textColor),
          ),
          iconTheme: IconThemeData(color: widget.theme.textColor),
          elevation: 0,
        ),
        body: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme Section
                    Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildThemeGrid(),
                    const SizedBox(height: 32),

                    // Font Family Section
                    Text(
                      'Font Family',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFontList(),
                    const SizedBox(height: 32),

                    // Font Weight Section
                    Text(
                      'Font Weight',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFontWeightList(),
                    const SizedBox(height: 32),

                    // Font Size Section
                    Text(
                      'Font Size',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFontSizeSlider(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(
        widget.themes.length,
        (index) => GestureDetector(
          onTap: () => widget.onThemeChanged(index),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: widget.themes[index].backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.currentThemeIndex == index
                    ? widget.theme.accentColor
                    : widget.theme.secondaryTextColor.withValues(alpha: 0.3),
                width: widget.currentThemeIndex == index ? 3 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: widget.themes[index].accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.themes[index].name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.themes[index].textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFontList() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.availableFonts.length,
        itemBuilder: (context, index) {
          final font = widget.availableFonts[index];
          return ListTile(
            title: Text(
              font,
              style: GoogleFonts.getFont(font, color: widget.theme.textColor),
            ),
            trailing: widget.selectedFont == font
                ? Icon(Icons.check_circle, color: widget.theme.accentColor)
                : null,
            onTap: () => widget.onFontChanged(font),
          );
        },
      ),
    );
  }

  Widget _buildFontWeightList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.fontWeights.entries.map((entry) {
        final isSelected = widget.fontWeight == entry.value;
        return GestureDetector(
          onTap: () => widget.onFontWeightChanged(entry.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.theme.accentColor
                  : widget.theme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? widget.theme.accentColor
                    : widget.theme.secondaryTextColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              entry.key,
              style: TextStyle(
                color: isSelected ? Colors.white : widget.theme.textColor,
                fontWeight: entry.value,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFontSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.fontSize.toStringAsFixed(0)} pt',
          style: TextStyle(
            fontSize: 16,
            color: widget.theme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: widget.theme.accentColor,
            inactiveTrackColor:
                widget.theme.secondaryTextColor.withValues(alpha: 0.3),
            thumbColor: widget.theme.accentColor,
            overlayColor: widget.theme.accentColor.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: widget.fontSize,
            min: 10,
            max: 40,
            divisions: 30,
            onChanged: (value) => widget.onFontSizeChanged(value),
          ),
        ),
      ],
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
