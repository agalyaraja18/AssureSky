import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/weather_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/bloc/home_bloc.dart';
import '../bloc/settings_bloc.dart';

class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({super.key});

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _filtered = ApiConstants.indianCities;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = ApiConstants.indianCities;
      } else {
        _filtered = ApiConstants.indianCities
            .where((c) =>
                c.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _selectCity(BuildContext context, String city) async {
    // Get lat/lon from weather API
    try {
      final repo = WeatherRepository();
      final results = await repo.searchCity(city);
      if (results.isNotEmpty) {
        final lat = (results[0]['lat'] as num).toDouble();
        final lon = (results[0]['lon'] as num).toDouble();

        if (context.mounted) {
          context
              .read<SettingsBloc>()
              .add(LocationChanged(city, lat, lon));
          context.read<HomeBloc>().add(HomeCityChanged(city, lat, lon));
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not find location. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCity =
        context.read<SettingsBloc>().state.cityName;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Search Location')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search city...',
                prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (context, i) {
                final city = _filtered[i];
                final isSelected = city == currentCity;
                return ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: isSelected
                        ? AppColors.accent
                        : theme.textTheme.bodySmall?.color,
                    size: 20,
                  ),
                  title: Text(
                    city,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isSelected ? AppColors.accent : null,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check,
                          color: AppColors.accent)
                      : null,
                  onTap: () => _selectCity(context, city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
