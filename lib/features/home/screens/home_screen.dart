import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/air_quality_model.dart';
import '../../../core/models/current_weather_model.dart';
import '../../../core/services/asky_engine.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/weather_alert_engine.dart';
import '../../../core/services/weather_repository.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_bloc.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/weather_animation_background.dart';
import '../../../core/widgets/weather_icon.dart';
import '../../../core/widgets/weather_mascot.dart';
import '../../alerts/screens/alert_detail_screen.dart';
import '../../alerts/screens/alerts_screen.dart';
import '../../alerts/widgets/official_alert_card.dart';
import '../../asky/screens/asky_screen.dart';
import '../../forecast/screens/forecast_screen.dart';
import '../../map/screens/world_map_screen.dart';
import '../../news/screens/news_screen.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../../settings/screens/search_location_screen.dart';
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

  /// Notification permission is asked only after the first weather load. Asking
  /// at start-up collides with the location permission dialog (Android allows
  /// one permission request at a time), which cancelled the location request
  /// and left the home screen loading forever.
  bool _askedNotificationPermission = false;

  Future<void> _askNotificationPermission() async {
    final wasEnabled = await NotificationService.areEnabled();
    final granted = await NotificationService.requestPermission();
    // Anything that was due while notifications were blocked is sent now.
    if (!wasEnabled && granted && mounted) {
      _homeBloc.add(HomeRefreshRequested());
    }
  }

  // Tab order: 0 Home · 1 Forecast · 2 News · 3 Asky · 4 Alerts · 5 Settings
  static const int _alertsTab = 4;

  void _goToAsky() {
    setState(() => _currentIndex = 3);
  }

  void _goToAlerts() {
    setState(() => _currentIndex = _alertsTab);
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
      // Keep Settings in step with the location Home actually resolved (GPS
      // fix, chosen city…) so the Settings → Location row is never stale.
      child: BlocListener<HomeBloc, HomeState>(
        listenWhen: (previous, current) => current is HomeLoaded,
        listener: (context, state) {
          if (state is HomeLoaded) {
            _settingsBloc
                .add(LocationChanged(state.cityName, state.lat, state.lon));
            if (!_askedNotificationPermission) {
              _askedNotificationPermission = true;
              unawaited(_askNotificationPermission());
            }
          }
        },
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return Scaffold(
              backgroundColor: themeState.themeData.scaffoldBackgroundColor,
              body: WeatherAnimationBackground(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    const _HomeTab(),
                    const ForecastScreen(),
                    const NewsScreen(),
                    const AskyScreen(),
                    // Only starts downloading once the tab is first opened.
                    AlertsScreen(active: _currentIndex == _alertsTab),
                    const SettingsScreen(),
                  ],
                ),
              ),
              bottomNavigationBar: _buildBottomNav(themeState),
            );
          },
        ),
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
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Alerts'),
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
                  _TopBar(
                    cityName: state.cityName,
                    isGps: state.locationSource == LocationSource.gps,
                    onTap: () => _openLocationSearch(context),
                    onMapTap: () => _openWorldMap(context, state),
                  ),
                  const SizedBox(height: 16),

                  // Status banners
                  if (state.fromCache) ...[
                    OfflineBanner(cachedAt: state.cachedAt),
                    const SizedBox(height: 12),
                  ],
                  if (state.locationSource == LocationSource.lastKnown ||
                      state.locationSource == LocationSource.fallback) ...[
                    const InfoBanner(
                      icon: Icons.location_disabled,
                      text:
                          'GPS unavailable — showing your last known location. Tap the city to choose another.',
                    ),
                    const SizedBox(height: 12),
                  ],

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

                  // Asky mascot: sleeps at night, reacts to the weather by day
                  WeatherMascotCard(
                    mood: mascotMoodFor(
                      code: weather.conditionCode,
                      tempC: weather.temp,
                      windKmh: weather.windSpeed,
                      visibilityMeters: weather.visibility,
                      humidity: weather.humidity,
                      hour: weather.cityNow.hour,
                      isHail: state.hasHail,
                    ),
                  ),
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
                  const SizedBox(height: 12),

                  // Sunrise / Sunset
                  _SunriseSunsetCard(weather: weather, theme: theme),
                  const SizedBox(height: 12),

                  // Weather alerts for the user's location (below Asky)
                  _LocationAlertsSection(
                    state: state,
                    onSeeAll: () => context
                        .findAncestorStateOfType<_HomeScreenState>()
                        ?._goToAlerts(),
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

/// Opens the world city search from the home screen.
void _openLocationSearch(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<SettingsBloc>()),
        BlocProvider.value(value: context.read<HomeBloc>()),
      ],
      child: const SearchLocationScreen(),
    ),
  ));
}

/// Opens the zoomable world weather map centred on the current city.
void _openWorldMap(BuildContext context, HomeLoaded state) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<SettingsBloc>()),
        BlocProvider.value(value: context.read<HomeBloc>()),
      ],
      child: WorldMapScreen(
        currentCity: state.cityName,
        currentLat: state.lat,
        currentLon: state.lon,
      ),
    ),
  ));
}

class _TopBar extends StatelessWidget {
  final String cityName;
  final bool isGps;
  final VoidCallback onTap;
  final VoidCallback onMapTap;
  const _TopBar(
      {required this.cityName,
      required this.isGps,
      required this.onTap,
      required this.onMapTap});

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
        // Globe button (world weather map) + tap the city to switch place.
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'World weather map',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.public, color: AppColors.accent),
                onPressed: onMapTap,
              ),
              Flexible(child: _cityButton(theme)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cityButton(ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isGps ? Icons.my_location : Icons.location_on,
                color: AppColors.accent, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(cityName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.arrow_drop_down,
                color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}

/// Stack of weather alert cards, most severe first.
class _AlertsSection extends StatelessWidget {
  final List<WeatherAlert> alerts;
  const _AlertsSection({required this.alerts});

  static Color _color(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.severe:
        return AppColors.red;
      case AlertSeverity.warning:
        return AppColors.orange;
      case AlertSeverity.advisory:
        return AppColors.yellow;
    }
  }

  static String _label(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.severe:
        return 'SEVERE';
      case AlertSeverity.warning:
        return 'WARNING';
      case AlertSeverity.advisory:
        return 'ADVISORY';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final alert in alerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _color(alert.severity).withValues(alpha: 0.8),
                    width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label(alert.severity),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _color(alert.severity),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            fontSize: 10,
                          ),
                        ),
                        Text(alert.title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(alert.message, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                WeatherIcon(weather.conditionCode,
                    size: 72, isNight: weather.isNight),
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
                      // Time in the *city shown*, not the phone's timezone.
                      Text(DateFormatter.formatTime(weather.cityNow),
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
                Text('Asky - AI Weather Advisor',
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

/// "Weather alerts · {city}" — official alerts that apply to the user's
/// location, followed by warnings derived from the live conditions.
class _LocationAlertsSection extends StatelessWidget {
  final HomeLoaded state;
  final VoidCallback onSeeAll;
  const _LocationAlertsSection({required this.state, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final official = state.officialAlerts;
    final conditions = state.alerts;
    final hasAny = official.isNotEmpty || conditions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.accent, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Weather alerts · ${state.cityName}',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6)),
              child: const Text('See all →'),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Official alert lookup in progress
        if (!state.officialAlertsLoaded)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent),
                ),
                const SizedBox(width: 8),
                Text('Checking official alerts…',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),

        // Official alerts affecting this location
        for (final alert in official)
          OfficialAlertCard(
            alert: alert,
            compact: true,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AlertDetailScreen(alert: alert),
            )),
          ),

        // Warnings derived from the live readings
        if (conditions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 6),
            child: Text('Based on current conditions',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          _AlertsSection(alerts: conditions),
        ],

        // All clear
        if (!hasAny && state.officialAlertsLoaded)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No active weather alerts for ${state.cityName}',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        if (state.officialAlertsFailed.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Some alert sources couldn\'t be reached right now.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
