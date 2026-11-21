<p align="center">
  <h1 align="center">AssureSky ☁️</h1>
  <p align="center"><b>Know your day. Own your day.</b></p>
  <p align="center">A weather app with AI Advice powered by Flutter.</p>
</p>

<p align="center">
  <a href="../../releases/latest">
    <img src="https://img.shields.io/github/v/release/YOUR_USERNAME/AssureSky?label=Download%20APK&logo=android&color=4CAF50" alt="Download APK"/>
  </a>
  <img src="https://img.shields.io/github/actions/workflow/status/YOUR_USERNAME/AssureSky/release.yml?branch=main&label=Build&logo=github-actions" alt="Build Status"/>
  <img src="https://img.shields.io/badge/Flutter-3.32-blue?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20iOS-informational" alt="Platforms"/>
</p>

---

## Features

- **Live weather** — temperature, weather conditions, humidity, wind, UV, visibility, auto pressure and AQI, with the date, day and time of your location
- **Sunrise & sunset** times for your location
- **Forecast** — 7-day forecast and 24-hour hourly weather breakdown
- **Asky, your AI weather advisor** — a fluffy cloud mascot that gives advice tips for the weather of the day. It wakes up in the morning, sleeps at night and acts out the weather in between (umbrella in rain, kite in a breeze, sunglasses in the sun…)
- **Official weather alerts** — warnings from India (IMD / NDMA), USA (NWS), Canada, Europe (MeteoAlarm) and worldwide disasters (GDACS), with safety tips. Alerts for your location also show on the home screen
- **World weather map** — zoomable map with the temperature, weather icon and local time of cities everywhere; tap any spot to see its weather
- **Weather news** — live, weather-only headlines from around the world, readable inside the app
- **Any city worldwide** — GPS or search, with unit settings for temperature, wind and auto pressure
- **Themes that change with the weather** — Sunny, Rainy, Snowy, Foggy, Hot, Cold, Thunderstorm, Cyclone and more, or pick your own
- **Notifications** — daily forecast, Asky advice, weather alerts and weather news
- **Offline cache** — shows the last loaded weather, forecast, news and alerts when there is no internet
- **Animated weather backgrounds** that match the conditions

## Download

| Platform | Link |
|----------|------|
| 🤖 Android | [**Download APK**](../../releases/latest) |
| 🌐 Web | [**Download Web Bundle**](../../releases/latest) |

> The APK is built automatically on every push via GitHub Actions and attached to the latest release.

## Screenshots

*Coming soon*

## Getting Started (Development)

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.32+
- Android Studio or VS Code with Flutter extension
- API keys from:
  - [OpenWeatherMap](https://openweathermap.org/api) (free tier)
  - [NewsAPI](https://newsapi.org/) (free tier)

### Setup

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/AssureSky.git
cd AssureSky/assuresky

# Install dependencies
flutter pub get

# Run with your API keys injected
flutter run \
  --dart-define=OWM_API_KEY=your_openweathermap_key \
  --dart-define=NEWS_API_KEY=your_newsapi_key
```

### Build APK locally

```bash
flutter build apk --release \
  --dart-define=OWM_API_KEY=your_key \
  --dart-define=NEWS_API_KEY=your_key
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## GitHub Actions CI/CD

This project uses GitHub Actions to automatically build and publish releases.

### Setup secrets

In your GitHub repo go to **Settings → Secrets and variables → Actions** and add:

| Secret Name | Value |
|-------------|-------|
| `OWM_API_KEY` | Your OpenWeatherMap API key |
| `NEWS_API_KEY` | Your NewsAPI key |

Every push to `main` will automatically:
1. Build an Android APK
2. Build a Flutter Web bundle
3. Create a GitHub Release with both files attached as downloadable assets

## Project Structure

```
assuresky/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/     # API endpoints & keys (dart-define), world map cities
│   │   ├── models/        # Weather, forecast, UV, alert & map data models
│   │   ├── services/      # Weather, news, location, notifications, offline cache
│   │   │   └── alerts/    # Official alert providers (NDMA, NWS, ECCC, MeteoAlarm, GDACS)
│   │   ├── theme/         # App themes & colors
│   │   ├── utils/         # Helpers, formatters & weather news filter
│   │   └── widgets/       # Asky mascot, weather icons & animated backgrounds
│   └── features/
│       ├── home/          # Main weather dashboard
│       ├── forecast/      # 7-day & hourly forecast
│       ├── asky/          # AI weather advisor tips
│       ├── alerts/        # Official weather alerts
│       ├── map/           # Zoomable world weather map
│       ├── news/          # Weather news feed
│       ├── settings/      # Settings, location search & themes
│       └── splash/        # Splash screen
├── android/               # Android native config
├── ios/                   # iOS native config
├── web/                   # Web entry point
├── design/                # App icon source & generator script
├── test/                  # Tests
├── .github/workflows/     # GitHub Actions build & release
└── assets/images/         # App assets
```

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter | Mobile application development |
| Dart | Frontend programming language |
| OpenWeatherMap API | Weather information and forecasts |
| NewsAPI | Trending news and articles |
| Figma | UI/UX design and prototyping |
| Open-Meteo API | UV index, 7-day forecast and weather for the world map |
| Open-Meteo Geocoding API | Searching for any city worldwide |
| NDMA SACHET (India) | Official Indian weather alerts from IMD and state authorities |
| US National Weather Service API | Official US weather alerts |
| Environment Canada | Official Canadian weather alerts |
| MeteoAlarm | Official European weather warnings |
| GDACS (UN / EU) | Worldwide cyclone, flood and drought alerts |
| Esri map tiles | Map images for the world weather map |

## License

This project is licensed under the MIT License.
