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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.currentTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.currentTheme.surfaceColor,
        title: Text(
          'Themes',
          style: TextStyle(color: widget.currentTheme.textColor),
        ),
        iconTheme: IconThemeData(color: widget.currentTheme.textColor),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: widget.currentTheme.textColor),
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
                color: widget.currentTheme.textColor,
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
                  color: widget.currentTheme.textColor,
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
        final isSelected = widget.currentThemeIndex == index;

        return GestureDetector(
          onTap: () => widget.onThemeChanged(index),
          onLongPress: isBuiltIn ? null : () => _showDeleteThemeDialog(index, theme),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 140,
            height: 160,
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? widget.currentTheme.accentColor
                    : widget.currentTheme.secondaryTextColor.withValues(alpha: 0.3),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: widget.currentTheme.accentColor.withValues(alpha: 0.3),
                        blurRadius: 12,
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
                    _buildColorDot(theme.primaryColor),
                    const SizedBox(width: 4),
                    _buildColorDot(theme.accentColor),
                    const SizedBox(width: 4),
                    _buildColorDot(theme.surfaceColor),
                  ],
                ),
                const SizedBox(height: 12),
                // Text preview
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Aa',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  theme.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (isSelected)
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
        );
      }).toList(),
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

  void _showDeleteThemeDialog(int index, CustomTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.currentTheme.surfaceColor,
        title: Text(
          'Delete Theme',
          style: TextStyle(color: widget.currentTheme.textColor),
        ),
        content: Text(
          'Are you sure you want to delete "${theme.name}"?',
          style: TextStyle(color: widget.currentTheme.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: widget.currentTheme.secondaryTextColor)),
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
    Color backgroundColor = widget.currentTheme.backgroundColor;
    Color surfaceColor = widget.currentTheme.surfaceColor;
    Color primaryColor = widget.currentTheme.primaryColor;
    Color textColor = widget.currentTheme.textColor;
    Color secondaryTextColor = widget.currentTheme.secondaryTextColor;
    Color accentColor = widget.currentTheme.accentColor;
    Brightness brightness = widget.currentTheme.brightness;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.currentTheme.surfaceColor,
          title: Text(
            'Create Custom Theme',
            style: TextStyle(color: widget.currentTheme.textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: widget.currentTheme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Theme Name',
                    labelStyle: TextStyle(color: widget.currentTheme.secondaryTextColor),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: widget.currentTheme.secondaryTextColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: widget.currentTheme.accentColor),
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
                    Text('Dark Mode', style: TextStyle(color: widget.currentTheme.textColor)),
                    Switch(
                      value: brightness == Brightness.dark,
                      activeTrackColor: widget.currentTheme.accentColor,
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
                style: TextStyle(color: widget.currentTheme.secondaryTextColor),
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
              child: Text('Create', style: TextStyle(color: widget.currentTheme.accentColor)),
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
          Text(label, style: TextStyle(color: widget.currentTheme.textColor)),
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
                border: Border.all(color: widget.currentTheme.secondaryTextColor),
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
        backgroundColor: widget.currentTheme.surfaceColor,
        title: Text('Pick a Color', style: TextStyle(color: widget.currentTheme.textColor)),
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
                              ? widget.currentTheme.accentColor
                              : widget.currentTheme.secondaryTextColor,
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

