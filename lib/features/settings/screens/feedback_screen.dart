import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _nameController = TextEditingController();
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _selectedRating = -1;

  final _emojis = ['😞', '😐', '🙂', '😊', '🤩'];

  @override
  void dispose() {
    _nameController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Thank you for your feedback!'),
          backgroundColor: AppColors.accent,
          duration: Duration(seconds: 3),
        ),
      );
      _nameController.clear();
      _feedbackController.clear();
      setState(() => _selectedRating = -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const Text('💬', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      "We'd love to hear your thoughts about AssureSky!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              Text('Your Name',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name...',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Feedback field
              Text('Your Feedback',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                      'Tell us what you think — what you love, what can be improved, or report a bug...',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Feedback is required'
                        : null,
              ),
              const SizedBox(height: 20),

              // Rating
              Text('Rating',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _emojis.length,
                  (i) => GestureDetector(
                    onTap: () => setState(() => _selectedRating = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedRating == i
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _selectedRating == i
                            ? Border.all(
                                color: AppColors.accent, width: 2)
                            : null,
                      ),
                      child: Text(
                        _emojis[i],
                        style: TextStyle(
                            fontSize: _selectedRating == i ? 36 : 28),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Submit Feedback',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
