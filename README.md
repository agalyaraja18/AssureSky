<p align="center">
  <h1 align="center">AssureSky ☁️</h1>
  <p align="center"><b>Know your day. Own your day.</b></p>
  <p align="center">A smart weather & news app powered by Flutter.</p>
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

- **Real-time weather** — current conditions, hourly & 7-day forecast
- **Air quality index** with health recommendations
- **AI-powered daily advice** (AskY) based on current conditions
- **Weather news** — latest headlines tailored to weather events
- **Location-aware** — auto-detects your city or search any Indian city
- **Animated backgrounds** that change with weather conditions
- **Dark-first premium UI** built with Flutter

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
│   ├── core/
│   │   ├── constants/     # API endpoints & keys (dart-define)
│   │   ├── models/        # Shared data models
│   │   ├── services/      # HTTP & location services
│   │   ├── theme/         # App theme & colors
│   │   ├── utils/         # Helpers & formatters
│   │   └── widgets/       # Reusable UI components
│   └── features/
│       ├── home/          # Main weather dashboard
│       ├── forecast/      # 7-day forecast screen
│       ├── asky/          # AI advice feature
│       ├── news/          # Weather news feed
│       ├── settings/      # App settings
│       └── splash/        # Splash screen
├── android/               # Android native config
├── ios/                   # iOS native config
├── web/                   # Web entry point
└── assets/images/         # App assets
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.32 |
| State Management | flutter_bloc |
| HTTP | Dio |
| Location | geolocator + geocoding |
| Storage | shared_preferences |
| Image Caching | cached_network_image |
| In-app Browser | webview_flutter |
| Weather Data | OpenWeatherMap API |
| News Data | NewsAPI |

## License

This project is licensed under the MIT License.
