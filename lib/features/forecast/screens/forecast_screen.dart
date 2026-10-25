import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/utils/weather_icon_helper.dart';
import '../../../core/services/weather_repository.dart';
import '../../home/bloc/home_bloc.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../bloc/forecast_bloc.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  bool _isWeekly = true;
  late ForecastBloc _forecastBloc;

  @override
  void initState() {
    super.initState();
    _forecastBloc = ForecastBloc(repository: WeatherRepository());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final homeState = context.read<HomeBloc>().state;
    if (homeState is HomeLoaded) {
      _forecastBloc
          .add(ForecastLoadRequested(homeState.lat, homeState.lon));
    }
  }

  @override
  void dispose() {
    _forecastBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _forecastBloc,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, homeState) {
          final cityName =
              homeState is HomeLoaded ? homeState.cityName : '';
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context, cityName),
                  _buildToggle(),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String cityName) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Forecast',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Row(children: [
            const Icon(Icons.location_on, color: AppColors.accent, size: 16),
            const SizedBox(width: 4),
            Text(cityName, style: theme.textTheme.titleMedium),
          ]),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleButton(
                label: '7 Days',
                selected: _isWeekly,
                onTap: () => setState(() => _isWeekly = true)),
            _ToggleButton(
                label: 'Hourly',
                selected: !_isWeekly,
                onTap: () => setState(() => _isWeekly = false)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<ForecastBloc, ForecastState>(
      builder: (context, state) {
        if (state is ForecastLoading || state is ForecastInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (state is ForecastError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final hs = context.read<HomeBloc>().state;
                    if (hs is HomeLoaded) {
                      _forecastBloc.add(
                          ForecastLoadRequested(hs.lat, hs.lon));
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state is ForecastLoaded) {
          return _isWeekly
              ? _WeeklyView(forecast: state.forecast)
              : _HourlyView(forecast: state.forecast);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleButton(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _WeeklyView extends StatelessWidget {
  final dynamic forecast;
  const _WeeklyView({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsBloc>().state;
    final theme = Theme.of(context);
    final days = forecast.daily;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: List.generate(days.length, (i) {
              final day = days[i];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            DateFormatter.formatDayDate(day.date),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          WeatherIconHelper.emoji(day.conditionCode),
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(day.condition,
                              style: theme.textTheme.bodyMedium),
                        ),
                        Text(
                          UnitConverter.formatTemp(
                              day.tempMax, settings.tempUnit),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (i < days.length - 1)
                    Divider(
                        height: 1,
                        color: theme.dividerColor),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Rain chance chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chance of Rain This Week',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: CustomPaint(
                    painter: _RainChartPainter(
                      days: days,
                      textColor: theme.textTheme.bodySmall?.color ??
                          Colors.grey,
                    ),
                    size: Size.infinite,
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

class _RainChartPainter extends CustomPainter {
  final List days;
  final Color textColor;
  _RainChartPainter({required this.days, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;
    final barPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final int count = days.length;
    final double barWidth = (size.width / count) * 0.5;
    final double spacing = size.width / count;
    const double maxBarHeight = 80;
    const double labelHeight = 20;

    for (int i = 0; i < count; i++) {
      final double rain = (days[i].rainChance as num).toDouble();
      final double barH = (rain / 100) * maxBarHeight;
      final double x = i * spacing + spacing / 2;
      final double top = maxBarHeight - barH;

      // Draw bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 2, top, barWidth, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);

      // Percentage label above bar
      final pctSpan = TextSpan(
        text: '${rain.toInt()}%',
        style: TextStyle(fontSize: 9, color: textColor),
      );
      final pctPainter = TextPainter(
          text: pctSpan, textDirection: TextDirection.ltr);
      pctPainter.layout();
      pctPainter.paint(
          canvas,
          Offset(x - pctPainter.width / 2,
              top - pctPainter.height - 2));

      // Day label below
      final daySpan = TextSpan(
        text: DateFormatter.formatDayName(days[i].date),
        style: TextStyle(fontSize: 9, color: textColor),
      );
      final dayPainter = TextPainter(
          text: daySpan, textDirection: TextDirection.ltr);
      dayPainter.layout();
      dayPainter.paint(
          canvas,
          Offset(
              x - dayPainter.width / 2, maxBarHeight + labelHeight - 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HourlyView extends StatelessWidget {
  final dynamic forecast;
  const _HourlyView({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsBloc>().state;
    final theme = Theme.of(context);
    final hours = forecast.hourly;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: hours.length,
      itemBuilder: (context, i) {
        final hour = hours[i];
        final uvLabel = UnitConverter.uvLabel(hour.uvIndex);
        Color uvColor = AppColors.green;
        if (uvLabel == 'Moderate') uvColor = Colors.orange;
        if (uvLabel == 'High' || uvLabel == 'Very High') {
          uvColor = AppColors.red;
        }

        // Time label: "Now" for first entry, day name for next-day entries
        final isFirst = i == 0;
        final isNextDay = hour.time.day != hours.first.time.day;
        final timeLabel = isFirst
            ? 'Now'
            : isNextDay
                ? DateFormatter.formatHourWithDay(hour.time)
                : DateFormatter.formatHour(hour.time);

        // Determine day/night for weather icon
        final hourVal = hour.time.hour;
        final isNight = hourVal < 6 || hourVal >= 18;

        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    timeLabel,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  WeatherIconHelper.emoji(hour.conditionCode,
                      isNight: isNight),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(hour.condition,
                      style: theme.textTheme.bodyMedium),
                ),
                Text(
                  UnitConverter.formatTemp(
                      hour.temp, settings.tempUnit),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: uvColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'UV $uvLabel',
                    style: TextStyle(
                        color: uvColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
