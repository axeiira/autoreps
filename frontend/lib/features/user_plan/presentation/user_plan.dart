import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_autoreps/widgets/app_scaffold.dart';
import 'package:flutter_autoreps/features/user_plan/data/repositories/user_profile_repository.dart';

class UserPlanPage extends StatefulWidget {
  const UserPlanPage({super.key});
  static const routeName = '/user-plan';

  @override
  State<UserPlanPage> createState() => _UserPlanPageState();
}

class _UserPlanPageState extends State<UserPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final _profileRepository = UserProfileRepository();

  String? _primaryGoal;
  String? _situpLevel;
  bool _isLoading = false;

  final List<String> _goals = [
    'Lose weight',
    'Build strength',
    'Improve endurance',
  ];

  final List<String> _levels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _profileRepository.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that goal and level are selected
    if (_primaryGoal == null || _primaryGoal!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a fitness goal'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_situpLevel == null || _situpLevel!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your experience level'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final int age = int.parse(_ageController.text.trim());
      final double weight = double.parse(_weightController.text.trim());

      await _profileRepository.saveProfile(
        age: age,
        weight: weight,
        primaryGoal: _primaryGoal!,
        experienceLevel: _situpLevel!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!'), backgroundColor: Colors.green),
      );

      // Navigate back to home
      Navigator.pushNamed(context, '/home');
    } on UserProfileException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'User Plan',
      showBottomNav: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back arrow + spacing
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pushNamed(context, '/home'),
                ),
                const SizedBox(width: 8),
                const Text('Home', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Age
                      const Text('Age', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter your age',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter your age';
                          final parsed = int.tryParse(v.trim());
                          if (parsed == null) return 'Age must be a whole number';
                          if (parsed <= 0 || parsed > 120) return 'Enter a valid age';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Weight
                      const Text('Weight (kg)', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*'))],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter your weight (e.g. 72.5)',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter your weight';
                          final parsed = double.tryParse(v.trim());
                          if (parsed == null) return 'Weight must be a number';
                          if (parsed <= 0 || parsed > 500) return 'Enter a realistic weight';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Primary Fitness Goals
                      const Text('Primary Fitness Goal', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _primaryGoal,
                        items: _goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => setState(() => _primaryGoal = v),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Please select a goal' : null,
                      ),

                      const SizedBox(height: 16),

                      // Sit Up Experience Level
                      const Text('Sit Up Experience Level', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _situpLevel,
                        items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                        onChanged: (v) => setState(() => _situpLevel = v),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Please select your level' : null,
                      ),

                      const SizedBox(height: 24),

                      // Save button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
