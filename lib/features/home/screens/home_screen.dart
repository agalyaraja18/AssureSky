import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/air_quality_model.dart';
import '../../../core/models/current_weather_model.dart';
import '../../../core/services/asky_engine.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/weather_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_bloc.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/utils/weather_icon_helper.dart';
import '../../../core/widgets/weather_animation_background.dart';
import '../../asky/screens/asky_screen.dart';
import '../../forecast/screens/forecast_screen.dart';
import '../../news/screens/news_screen.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../../settings/screens/settings_screen.dart';
import '../bloc/home_bloc.dart';
import 'weather_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late HomeBloc _homeBloc;
  late SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();
    final themeBloc = context.read<ThemeBloc>();
    _homeBloc = HomeBloc(
      repository: WeatherRepository(),
      locationService: LocationService(),
      themeBloc: themeBloc,
    )..add(HomeLoadRequested());

    _settingsBloc = SettingsBloc()..add(SettingsLoaded());
  }

  void _goToAsky() {
    setState(() => _currentIndex = 3);
  }

  @override
  void dispose() {
    _homeBloc.close();
    _settingsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeBloc),
        BlocProvider.value(value: _settingsBloc),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return Scaffold(
            backgroundColor: themeState.themeData.scaffoldBackgroundColor,
            body: WeatherAnimationBackground(
              child: IndexedStack(
                index: _currentIndex,
                children: const [
                  _HomeTab(),
                  ForecastScreen(),
                  NewsScreen(),
                  AskyScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNav(themeState),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(ThemeState themeState) {
    final cardColor = themeState.themeData.cardColor;
    return NavigationBar(
      backgroundColor: cardColor,
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home'),
        NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Forecast'),
        NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'News'),
        NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Asky'),
        NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings'),
      ],
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return const _LoadingView();
        }
        if (state is HomeError) {
          return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<HomeBloc>().add(HomeLoadRequested()));
        }
        if (state is HomeLoaded) {
          return _WeatherView(state: state);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.accent),
          SizedBox(height: 16),
          Text('Loading weather data...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherView extends StatelessWidget {
  final HomeLoaded state;
  const _WeatherView({required this.state});

  @override
  Widget build(BuildContext context) {
    final weather = state.weather;
    final airQuality = state.airQuality;
    final askyResult = state.askyResult;
    final settings = context.watch<SettingsBloc>().state;
    final theme = Theme.of(context);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async =>
          context.read<HomeBloc>().add(HomeRefreshRequested()),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  _TopBar(cityName: state.cityName),
                  const SizedBox(height: 16),

                  // Main weather card
                  _MainWeatherCard(
                      weather: weather, settings: settings, theme: theme),
                  const SizedBox(height: 12),

                  // Stats row
                  _StatsRow(
                      weather: weather,
                      airQuality: airQuality,
                      settings: settings,
                      theme: theme),
                  const SizedBox(height: 12),

                  // Time & Date row
                  _TimeDateRow(weather: weather, theme: theme),
                  const SizedBox(height: 12),

                  // Sunrise / Sunset
                  _SunriseSunsetCard(weather: weather, theme: theme),
                  const SizedBox(height: 12),

                  // Asky banner
                  _AskyBanner(
                    askyResult: askyResult,
                    theme: theme,
                    onSeeMoreTips: () {
                      context
                          .findAncestorStateOfType<_HomeScreenState>()
                          ?._goToAsky();
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String cityName;
  const _TopBar({required this.cityName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AssureSky',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text('Know your day; Own your day',
                style: theme.textTheme.bodySmall),
          ],
        ),
        Row(
          children: [
            Icon(Icons.location_on,
                color: AppColors.accent, size: 16),
            const SizedBox(width: 4),
            Text(cityName,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _MainWeatherCard extends StatelessWidget {
  final CurrentWeatherModel weather;
  final SettingsState settings;
  final ThemeData theme;
  const _MainWeatherCard(
      {required this.weather,
      required this.settings,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        UnitConverter.formatTemp(
                            weather.temp, settings.tempUnit),
                        style: theme.textTheme.displayLarge,
                      ),
                      Text(weather.condition,
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Feels like ${UnitConverter.formatTemp(weather.feelsLike, settings.tempUnit)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'H: ${UnitConverter.formatTemp(weather.tempMax, settings.tempUnit)}  '
                        'L: ${UnitConverter.formatTemp(weather.tempMin, settings.tempUnit)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  WeatherIconHelper.emoji(weather.conditionCode),
                  style: const TextStyle(fontSize: 72),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<SettingsBloc>(),
                      child: WeatherDetailsScreen(
                        weather: weather,
                        airQuality:
                            (context.read<HomeBloc>().state as HomeLoaded)
                                .airQuality,
                        cityName:
                            (context.read<HomeBloc>().state as HomeLoaded)
                                .cityName,
                      ),
                    ),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Tap for details',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final CurrentWeatherModel weather;
  final AirQualityModel airQuality;
  final SettingsState settings;
  final ThemeData theme;
  const _StatsRow(
      {required this.weather,
      required this.airQuality,
      required this.settings,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
                icon: '💧',
                label: 'Humidity',
                value: '${weather.humidity}%'),
            _StatItem(
                icon: '💨',
                label: 'Wind',
                value: UnitConverter.formatWind(
                    weather.windSpeed, settings.windUnit)),
            _StatItem(
                icon: '☀️',
                label: 'UV Index',
                value: UnitConverter.uvLabel(weather.uvIndex)),
            _StatItem(
                icon: '🔵',
                label: 'Pressure',
                value: UnitConverter.formatPressure(
                    weather.pressure.toDouble(), settings.pressureUnit)),
            _StatItem(
                icon: '🌿',
                label: 'AQI',
                value: '${airQuality.aqi500}'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StatItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
        Text(label,
            style:
                theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _TimeDateRow extends StatelessWidget {
  final CurrentWeatherModel weather;
  final ThemeData theme;
  const _TimeDateRow({required this.weather, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.access_time,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormatter.formatTime(DateTime.now()),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Current Time',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormatter.formatDayName(weather.dt),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(DateFormatter.formatMonthDay(weather.dt),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SunriseSunsetCard extends StatelessWidget {
  final CurrentWeatherModel weather;
  final ThemeData theme;
  const _SunriseSunsetCard({required this.weather, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('🌅', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text('Sunrise',
                    style: theme.textTheme.bodySmall),
                Text(
                  DateFormatter.formatTime(weather.sunrise),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              height: 50,
              width: 1,
              color: theme.dividerColor,
            ),
            Column(
              children: [
                const Text('🌇', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text('Sunset', style: theme.textTheme.bodySmall),
                Text(
                  DateFormatter.formatTime(weather.sunset),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AskyBanner extends StatelessWidget {
  final AskyResult askyResult;
  final ThemeData theme;
  final VoidCallback onSeeMoreTips;
  const _AskyBanner({required this.askyResult, required this.theme, required this.onSeeMoreTips});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🌤️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('AI WEATHER ADVISOR',
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 8),
            Text(askyResult.primaryAdvice,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onSeeMoreTips,
              child: Text('See more tips →',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
