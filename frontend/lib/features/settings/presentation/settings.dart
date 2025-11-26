import 'package:flutter/material.dart';
import 'package:flutter_autoreps/widgets/app_scaffold.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  static const routeName = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  double _countdownDuration = 3.0;
  String _cameraPosition = 'Back';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      currentNavIndex: 3,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // General Section
                _buildSectionTitle('General'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildSwitchTile(
                      title: 'Notifications',
                      subtitle: 'Receive workout reminders',
                      value: _notificationsEnabled,
                      onChanged: (value) => setState(() => _notificationsEnabled = value),
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      title: 'Sound',
                      subtitle: 'Enable audio feedback',
                      value: _soundEnabled,
                      onChanged: (value) => setState(() => _soundEnabled = value),
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      title: 'Vibration',
                      subtitle: 'Haptic feedback on actions',
                      value: _vibrationEnabled,
                      onChanged: (value) => setState(() => _vibrationEnabled = value),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Training Section
                _buildSectionTitle('Training'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildSliderTile(
                      title: 'Countdown Duration',
                      subtitle: '${_countdownDuration.toInt()} seconds',
                      value: _countdownDuration,
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      onChanged: (value) => setState(() => _countdownDuration = value),
                    ),
                    _buildDivider(),
                    _buildDropdownTile(
                      title: 'Default Camera',
                      subtitle: 'Select camera position',
                      value: _cameraPosition,
                      items: ['Front', 'Back'],
                      onChanged: (value) => setState(() => _cameraPosition = value ?? 'Back'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // About Section
                _buildSectionTitle('About'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildActionTile(
                      title: 'Version',
                      subtitle: '1.0.0',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      title: 'Privacy Policy',
                      onTap: () {
                        // Navigate to privacy policy
                      },
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      title: 'Terms of Service',
                      onTap: () {
                        // Navigate to terms of service
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Danger Zone
                _buildSectionTitle('Data'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  borderColor: Colors.red.withOpacity(0.5),
                  children: [
                    _buildActionTile(
                      title: 'Clear Workout History',
                      subtitle: 'This action cannot be undone',
                      titleColor: Colors.red,
                      onTap: () {
                        _showClearDataDialog(context);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFC7F705),
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required List<Widget> children,
    Color? borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFC7F705),
            activeTrackColor: const Color(0xFFC7F705).withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    String? subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFC7F705),
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: const Color(0xFFC7F705),
              overlayColor: const Color(0xFFC7F705).withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    String? subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: const Color(0xFF1E1E2E),
            style: const TextStyle(
              color: Color(0xFFC7F705),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            underline: Container(),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (subtitle == null)
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.4),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.1),
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Clear Workout History?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'This will permanently delete all your workout history. This action cannot be undone.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                // Clear workout history
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Workout history cleared'),
                    backgroundColor: Color(0xFFC7F705),
                  ),
                );
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
