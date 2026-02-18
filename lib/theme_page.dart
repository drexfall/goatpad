import 'package:flutter/material.dart';
import 'main.dart';

class ThemePage extends StatefulWidget {
  final CustomTheme currentTheme;
  final List<CustomTheme> themes;
  final int currentThemeIndex;
  final Function(int) onThemeChanged;
  final Function(CustomTheme) onThemeCreated;
  final Function(int) onThemeDeleted;

  const ThemePage({
    super.key,
    required this.currentTheme,
    required this.themes,
    required this.currentThemeIndex,
    required this.onThemeChanged,
    required this.onThemeCreated,
    required this.onThemeDeleted,
  });

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  late int _selectedThemeIndex;

  @override
  void initState() {
    super.initState();
    _selectedThemeIndex = widget.currentThemeIndex;
  }

  CustomTheme get _currentDisplayTheme => widget.themes[_selectedThemeIndex];

  void _handleThemeChanged(int index) {
    setState(() {
      _selectedThemeIndex = index;
    });
    widget.onThemeChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentDisplayTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: _currentDisplayTheme.surfaceColor,
        title: Text(
          'Themes',
          style: TextStyle(color: _currentDisplayTheme.textColor),
        ),
        iconTheme: IconThemeData(color: _currentDisplayTheme.textColor),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: _currentDisplayTheme.textColor),
            tooltip: 'Create Custom Theme',
            onPressed: _showCreateThemeDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Built-in Themes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _currentDisplayTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildThemeGrid(
              widget.themes
                  .asMap()
                  .entries
                  .where((e) => CustomTheme.defaultThemes.any((d) => d.id == e.value.id))
                  .toList(),
              isBuiltIn: true,
            ),
            const SizedBox(height: 32),
            if (widget.themes.any((t) => !CustomTheme.defaultThemes.any((d) => d.id == t.id))) ...[
              Text(
                'Custom Themes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _currentDisplayTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildThemeGrid(
                widget.themes
                    .asMap()
                    .entries
                    .where((e) => !CustomTheme.defaultThemes.any((d) => d.id == e.value.id))
                    .toList(),
                isBuiltIn: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeGrid(List<MapEntry<int, CustomTheme>> themesWithIndex, {required bool isBuiltIn}) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: themesWithIndex.map((entry) {
        final index = entry.key;
        final theme = entry.value;
        final isSelected = _selectedThemeIndex == index;

        return _ThemeCard(
          theme: theme,
          currentTheme: _currentDisplayTheme,
          isSelected: isSelected,
          onTap: () => _handleThemeChanged(index),
          onLongPress: isBuiltIn ? null : () => _showDeleteThemeDialog(index, theme),
        );
      }).toList(),
    );
  }


  void _showDeleteThemeDialog(int index, CustomTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _currentDisplayTheme.surfaceColor,
        title: Text(
          'Delete Theme',
          style: TextStyle(color: _currentDisplayTheme.textColor),
        ),
        content: Text(
          'Are you sure you want to delete "${theme.name}"?',
          style: TextStyle(color: _currentDisplayTheme.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _currentDisplayTheme.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () {
              widget.onThemeDeleted(index);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreateThemeDialog() {
    final nameController = TextEditingController();
    Color backgroundColor = _currentDisplayTheme.backgroundColor;
    Color surfaceColor = _currentDisplayTheme.surfaceColor;
    Color primaryColor = _currentDisplayTheme.primaryColor;
    Color textColor = _currentDisplayTheme.textColor;
    Color secondaryTextColor = _currentDisplayTheme.secondaryTextColor;
    Color accentColor = _currentDisplayTheme.accentColor;
    Brightness brightness = _currentDisplayTheme.brightness;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _currentDisplayTheme.surfaceColor,
          title: Text(
            'Create Custom Theme',
            style: TextStyle(color: _currentDisplayTheme.textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: _currentDisplayTheme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Theme Name',
                    labelStyle: TextStyle(color: _currentDisplayTheme.secondaryTextColor),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _currentDisplayTheme.secondaryTextColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _currentDisplayTheme.accentColor),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildColorPicker('Background', backgroundColor, (color) {
                  setDialogState(() => backgroundColor = color);
                }),
                _buildColorPicker('Surface', surfaceColor, (color) {
                  setDialogState(() => surfaceColor = color);
                }),
                _buildColorPicker('Primary', primaryColor, (color) {
                  setDialogState(() => primaryColor = color);
                }),
                _buildColorPicker('Text', textColor, (color) {
                  setDialogState(() => textColor = color);
                }),
                _buildColorPicker('Secondary Text', secondaryTextColor, (color) {
                  setDialogState(() => secondaryTextColor = color);
                }),
                _buildColorPicker('Accent', accentColor, (color) {
                  setDialogState(() => accentColor = color);
                }),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Dark Mode', style: TextStyle(color: _currentDisplayTheme.textColor)),
                    Switch(
                      value: brightness == Brightness.dark,
                      activeTrackColor: _currentDisplayTheme.accentColor,
                      onChanged: (value) {
                        setDialogState(() {
                          brightness = value ? Brightness.dark : Brightness.light;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: _currentDisplayTheme.secondaryTextColor),
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

                  widget.onThemeCreated(newTheme);
                  Navigator.pop(context);
                }
              },
              child: Text('Create', style: TextStyle(color: _currentDisplayTheme.accentColor)),
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
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _currentDisplayTheme.textColor)),
          GestureDetector(
            onTap: () async {
              final color = await _showColorPickerDialog(currentColor);
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
                border: Border.all(color: _currentDisplayTheme.secondaryTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Color?> _showColorPickerDialog(Color currentColor) async {
    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _currentDisplayTheme.surfaceColor,
        title: Text('Pick a Color', style: TextStyle(color: _currentDisplayTheme.textColor)),
        content: SingleChildScrollView(
          child: Wrap(
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
              const Color(0xFF121212),
              const Color(0xFF1E1E1E),
              const Color(0xFF2E3440),
              const Color(0xFF3B4252),
              const Color(0xFFFAFAFA),
              const Color(0xFFE0E0E0),
            ]
                .map(
                  (color) => GestureDetector(
                    onTap: () => Navigator.pop(context, color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color == currentColor
                              ? _currentDisplayTheme.accentColor
                              : _currentDisplayTheme.secondaryTextColor,
                          width: color == currentColor ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatefulWidget {
  final CustomTheme theme;
  final CustomTheme currentTheme;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ThemeCard({
    required this.theme,
    required this.currentTheme,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 140,
          height: 160,
          transform: _isHovered && !widget.isSelected
              ? (Matrix4.identity()..setTranslationRaw(0.0, -4.0, 0.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: widget.theme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? widget.currentTheme.accentColor
                  : _isHovered
                      ? widget.currentTheme.accentColor.withValues(alpha: 0.6)
                      : widget.currentTheme.secondaryTextColor.withValues(alpha: 0.3),
              width: widget.isSelected ? 3 : _isHovered ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.currentTheme.accentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : _isHovered
                    ? [
                        BoxShadow(
                          color: widget.currentTheme.accentColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Color palette preview
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildColorDot(widget.theme.primaryColor),
                  const SizedBox(width: 4),
                  _buildColorDot(widget.theme.accentColor),
                  const SizedBox(width: 4),
                  _buildColorDot(widget.theme.surfaceColor),
                ],
              ),
              const SizedBox(height: 12),
              // Text preview
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.theme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Aa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.theme.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.theme.textColor,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              if (widget.isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: widget.currentTheme.accentColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
    );
  }
}
