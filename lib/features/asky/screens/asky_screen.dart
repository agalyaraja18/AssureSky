import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/asky_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/bloc/home_bloc.dart';

class AskyScreen extends StatelessWidget {
  const AskyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoaded) {
          return _AskyView(askyResult: state.askyResult);
        }
        if (state is HomeLoading || state is HomeInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }
        return const _AskyView(
          askyResult: AskyResult(
            primaryAdvice: 'Loading weather data...',
            tips: [],
          ),
        );
      },
    );
  }
}

class _AskyView extends StatelessWidget {
  final AskyResult askyResult;
  const _AskyView({required this.askyResult});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header card with Asky mascot
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _AskyMascot(),
                      const SizedBox(height: 16),
                      Text(
                        "Hello! I'm Asky",
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "I'm here to give you smart advice\nbased on the weather around you.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Today's Advice card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny_outlined,
                              color: AppColors.yellow, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Today's Advice",
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        askyResult.primaryAdvice,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tips section
              if (askyResult.tips.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tips for You',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...askyResult.tips.asMap().entries.map((entry) {
                          final i = entry.key;
                          final tip = entry.value;
                          return Column(
                            children: [
                              _TipRow(tip: tip),
                              if (i < askyResult.tips.length - 1)
                                Divider(
                                    height: 16,
                                    color: theme.dividerColor),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AskyMascot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '🌤️',
          style: TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final AskyTip tip;
  const _TipRow({required this.tip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(tip.icon, style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(tip.text, style: theme.textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}
