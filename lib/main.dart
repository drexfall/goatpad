import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goatpad/responsive_layout.dart';
import 'package:goatpad/share_dialog.dart';
import 'package:goatpad/theme_page.dart';
import 'package:goatpad/toolbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  DateTime? lastModified;
  StreamSubscription<FileSystemEvent>? fileWatcher;

  EditorTab({
    required this.id,
    required this.controller,
    this.filePath,
    this.hasUnsavedChanges = false,
    this.lastModified,
    this.fileWatcher,
  });

  String get fileName =>
      filePath?.split(Platform.pathSeparator).last ?? 'Untitled';

  void dispose() {
    controller.dispose();
    fileWatcher?.cancel();
  }
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
      tab.dispose();
    }
    super.dispose();
  }

  EditorTab get _currentTab => _tabs[_currentTabIndex];

  void _createNewTab(
      {String? filePath, String? content, DateTime? lastModified}) {
    final controller = TextEditingController(text: content ?? '');

    final tab = EditorTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      controller: controller,
      filePath: filePath,
      hasUnsavedChanges: false,
      lastModified: lastModified,
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

    // Set up file watching if we have a file path
    if (filePath != null && !kIsWeb) {
      _setupFileWatcher(tab);
    }
  }

  void _setupFileWatcher(EditorTab tab) {
    if (tab.filePath == null || kIsWeb) return;

    final file = File(tab.filePath!);
    if (!file.existsSync()) return;

    tab.fileWatcher?.cancel();

    try {
      final directory = file.parent;
      tab.fileWatcher = directory.watch().listen((event) {
        if (event.path == tab.filePath) {
          if (event is FileSystemModifyEvent ||
              event is FileSystemCreateEvent) {
            _handleExternalFileChange(tab);
          }
        }
      });
    } catch (e) {
      // File watching not supported on this platform
      debugPrint('File watching not supported: $e');
    }
  }

  Future<void> _handleExternalFileChange(EditorTab tab) async {
    if (tab.filePath == null) return;

    final file = File(tab.filePath!);
    if (!file.existsSync()) return;

    final fileStat = await file.stat();

    // Only reload if the file was modified after our last known modification
    if (tab.lastModified != null &&
        fileStat.modified.isAfter(tab.lastModified!)) {
      final content = await file.readAsString();

      // Check if content actually changed
      if (content != tab.controller.text) {
        if (mounted) {
          // Show dialog asking if user wants to reload
          final shouldReload = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: _themes[_currentThemeIndex].surfaceColor,
              title: Text(
                'File Changed',
                style: TextStyle(color: _themes[_currentThemeIndex].textColor),
              ),
              content: Text(
                '${tab.fileName} has been modified externally. Do you want to reload it?',
                style: TextStyle(
                    color: _themes[_currentThemeIndex].secondaryTextColor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Keep Mine',
                      style: TextStyle(
                          color:
                              _themes[_currentThemeIndex].secondaryTextColor)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Reload',
                      style: TextStyle(
                          color: _themes[_currentThemeIndex].accentColor)),
                ),
              ],
            ),
          );

          if (shouldReload == true && mounted) {
            setState(() {
              tab.controller.text = content;
              tab.lastModified = fileStat.modified;
              tab.hasUnsavedChanges = false;
            });
          }
        }
      }

      tab.lastModified = fileStat.modified;
    }
  }

  void _reorderTabs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final tab = _tabs.removeAt(oldIndex);
      _tabs.insert(newIndex, tab);

      // Update current tab index if necessary
      if (_currentTabIndex == oldIndex) {
        _currentTabIndex = newIndex;
      } else if (_currentTabIndex > oldIndex && _currentTabIndex <= newIndex) {
        _currentTabIndex--;
      } else if (_currentTabIndex < oldIndex && _currentTabIndex >= newIndex) {
        _currentTabIndex++;
      }
    });
  }

  void _closeTab(int index) async {
    if (_tabs[index].hasUnsavedChanges) {
      final shouldClose = await _showUnsavedDialog();
      if (shouldClose != true) return;
    }

    setState(() {
      _tabs[index].dispose();
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
      final fileStat = await file.stat();

      _createNewTab(
          filePath: filePath,
          content: content,
          lastModified: fileStat.modified);
      _showSnackBar('File opened successfully');
    }
  }

  Future<void> _saveFile() async {
    if (_currentTab.filePath != null) {
      final file = File(_currentTab.filePath!);
      await file.writeAsString(_currentTab.controller.text);
      final fileStat = await file.stat();
      setState(() {
        _currentTab.hasUnsavedChanges = false;
        _currentTab.lastModified = fileStat.modified;
      });
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
      final fileStat = await file.stat();

      setState(() {
        _currentTab.filePath = path;
        _currentTab.hasUnsavedChanges = false;
        _currentTab.lastModified = fileStat.modified;
      });

      // Set up file watching for the newly saved file
      if (!kIsWeb) {
        _setupFileWatcher(_currentTab);
      }

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

  void _showShareDialog() {
    final theme = _themes[_currentThemeIndex];
    showDialog(
      context: context,
      builder: (context) => ShareDialog(
        theme: theme,
        text: _currentTab.controller.text,
        onScanQR: _scanQRCode,
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

  void _openThemePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThemePage(
          currentTheme: _themes[_currentThemeIndex],
          themes: _themes,
          currentThemeIndex: _currentThemeIndex,
          onThemeChanged: (index) {
            setState(() => _currentThemeIndex = index);
            _saveSettings();
          },
          onThemeCreated: (newTheme) {
            setState(() {
              _themes.add(newTheme);
              _currentThemeIndex = _themes.length - 1;
            });
            _saveSettings();
            _showSnackBar('Custom theme created');
          },
          onThemeDeleted: (index) {
            if (index < _themes.length &&
                index >= CustomTheme.defaultThemes.length) {
              setState(() {
                _themes.removeAt(index);
                if (_currentThemeIndex >= _themes.length) {
                  _currentThemeIndex = _themes.length - 1;
                }
              });
              _saveSettings();
              _showSnackBar('Theme deleted');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themes[_currentThemeIndex];
    final isMobile = ResponsiveLayout.isMobile(context);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _saveFile,
        const SingleActivator(LogicalKeyboardKey.keyS,
            control: true, shift: true): _saveFileAs,
        const SingleActivator(LogicalKeyboardKey.keyS, alt: true):
            _showShareDialog,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
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
              handleSave: _saveFile,
              handleSaveAs: _saveFileAs,
              handleShare: _showShareDialog,
              selectedFont: _selectedFont,
              fontWeight: _fontWeight,
              fontSize: _fontSize,
              availableFonts: _availableFonts,
              fontWeights: _fontWeights,
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
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.palette_outlined, color: theme.textColor),
                tooltip: 'Themes',
                onPressed: _openThemePage,
              ),
              if (!isMobile)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: theme.textColor),
                  color: theme.surfaceColor,
                  onSelected: (value) {
                    switch (value) {
                      case 'about':
                        _showAboutDialog();
                        break;
                      case 'help':
                        _showHelpDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'about',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: theme.textColor, size: 20),
                          const SizedBox(width: 12),
                          Text('About',
                              style: TextStyle(color: theme.textColor)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'help',
                      child: Row(
                        children: [
                          Icon(Icons.help_outline,
                              color: theme.textColor, size: 20),
                          const SizedBox(width: 12),
                          Text('Help',
                              style: TextStyle(color: theme.textColor)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              // Reorderable Tab bar
              Container(
                height: 48,
                color: theme.surfaceColor,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  itemCount: _tabs.length,
                  onReorder: _reorderTabs,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: theme.backgroundColor,
                      elevation: 4,
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final tab = _tabs[index];
                    final isSelected = index == _currentTabIndex;

                    return ReorderableDragStartListener(
                      key: ValueKey(tab.id),
                      index: index,
                      child: Tooltip(
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
                                  color: theme.secondaryTextColor
                                      .withValues(alpha: 0.2),
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
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
          // Mobile Bottom Navigation
          bottomNavigationBar: isMobile ? _buildMobileBottomBar(theme) : null,
        ),
      ),
    );
  }

  Widget _buildMobileBottomBar(CustomTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMobileNavItem(
                icon: Icons.note_add,
                label: 'New',
                onTap: _newFile,
                theme: theme,
              ),
              _buildMobileNavItem(
                icon: Icons.folder_open,
                label: 'Open',
                onTap: _openFile,
                theme: theme,
              ),
              _buildMobileNavItem(
                icon: Icons.save,
                label: 'Save',
                onTap: _saveFile,
                theme: theme,
              ),
              _buildMobileNavItem(
                icon: Icons.share,
                label: 'Share',
                onTap: _showShareDialog,
                theme: theme,
              ),
              _buildMobileNavItem(
                icon: Icons.more_horiz,
                label: 'More',
                onTap: () => _showMobileMoreMenu(theme),
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required CustomTheme theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.textColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileMoreMenu(CustomTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.secondaryTextColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.save_as, color: theme.textColor),
                title:
                    Text('Save As', style: TextStyle(color: theme.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _saveFileAs();
                },
              ),
              ListTile(
                leading: Icon(Icons.qr_code_scanner, color: theme.textColor),
                title: Text('Scan QR Code',
                    style: TextStyle(color: theme.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _scanQRCode();
                },
              ),
              ListTile(
                leading: Icon(Icons.palette, color: theme.textColor),
                title: Text('Themes', style: TextStyle(color: theme.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _openThemePage();
                },
              ),
              ListTile(
                leading: Icon(Icons.text_fields, color: theme.textColor),
                title: Text('Font Settings',
                    style: TextStyle(color: theme.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _showMobileFontSettings(theme);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.info_outline, color: theme.textColor),
                title: Text('About', style: TextStyle(color: theme.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.help_outline, color: theme.textColor),
                title: Text('Help', style: TextStyle(color: theme.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _showHelpDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMobileFontSettings(CustomTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.secondaryTextColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Font Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Font Size: ${_fontSize.toInt()} pt',
                  style: TextStyle(color: theme.textColor),
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: theme.accentColor,
                    inactiveTrackColor:
                        theme.secondaryTextColor.withValues(alpha: 0.3),
                    thumbColor: theme.accentColor,
                  ),
                  child: Slider(
                    value: _fontSize,
                    min: 10,
                    max: 40,
                    divisions: 30,
                    onChanged: (value) {
                      setState(() => _fontSize = value);
                      setModalState(() {});
                      _saveSettings();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Font Weight',
                  style: TextStyle(color: theme.textColor),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _fontWeights.entries.map((entry) {
                    final isSelected = _fontWeight == entry.value;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _fontWeight = entry.value);
                        setModalState(() {});
                        _saveSettings();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.accentColor
                              : theme.backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? theme.accentColor
                                : theme.secondaryTextColor
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            color: isSelected ? Colors.white : theme.textColor,
                            fontWeight: entry.value,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Font Family',
                  style: TextStyle(color: theme.textColor),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _availableFonts.length,
                    itemBuilder: (context, index) {
                      final font = _availableFonts[index];
                      final isSelected = _selectedFont == font;
                      return ListTile(
                        title: Text(
                          font,
                          style:
                              GoogleFonts.getFont(font, color: theme.textColor),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: theme.accentColor)
                            : null,
                        onTap: () {
                          setState(() => _selectedFont = font);
                          setModalState(() {});
                          _saveSettings();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final theme = _themes[_currentThemeIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Row(
          children: [
            Image.asset('goatpad-logo.png', width: 40, height: 40),
            const SizedBox(width: 12),
            Text('GoatPad', style: TextStyle(color: theme.textColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The (allegedly) Greatest Of All Text editors',
              style: TextStyle(color: theme.secondaryTextColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: theme.secondaryTextColor, fontSize: 12),
            ),
          ],
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

  void _showHelpDialog() {
    final theme = _themes[_currentThemeIndex];
    final isDesktop = ResponsiveLayout.isDesktopOrTablet(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text('Help', style: TextStyle(color: theme.textColor)),
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          width: MediaQuery.of(context).size.width * 0.6,
          child: isDesktop
              ? Row(
            spacing: 48,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHelpItem(
                              'New File', 'Create a new empty document', theme),
                          _buildHelpItem(
                              'Open File', 'Open an existing text file', theme),
                          _buildHelpItem(
                              'Save', 'Save the current document', theme),
                          _buildHelpItem('Share',
                              'Share text via QR code or other apps', theme),
                          _buildHelpItem(
                              'Themes', 'Customize the app appearance', theme),
                          _buildHelpItem(
                              'Tabs', 'Drag tabs to reorder them', theme),
                          const SizedBox(height: 16),
                        ]),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Keyboard Shortcuts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildShortcutItem('Ctrl + S', 'Save', theme),
                        _buildShortcutItem(
                            'Ctrl + Shift + S', 'Save As', theme),
                        _buildShortcutItem('Alt + S', 'Share', theme),
                        _buildShortcutItem('Ctrl + C', 'Copy', theme),
                        _buildShortcutItem('Ctrl + X', 'Cut', theme),
                        _buildShortcutItem('Ctrl + V', 'Paste', theme),
                      ],
                    )
                  ],
                )
              : Column(),
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

  Widget _buildHelpItem(String title, String description, CustomTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(String shortcut, String action, CustomTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.secondaryTextColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                color: theme.textColor,
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            action,
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontSize: 13,
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
