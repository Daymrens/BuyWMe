# 🛒 BuyWMe — Grocery Mate

A fully offline, premium-feel grocery companion app built with Flutter. Designed for speed, privacy, and a delightful user experience — no accounts, no servers, just you and your shopping.

## ✨ Features

- **Smart Shopping Lists** — Create, manage, and organize multiple grocery lists with ease
- **Barcode Scanner** — Scan product barcodes to quickly add items using `mobile_scanner`
- **OCR Text Recognition** — Extract text from product labels using `google_mlkit_text_recognition`
- **Offline-First** — All data stored locally via Hive; works completely offline
- **Dark & Light Mode** — Dark mode first with a toggle for light mode
- **Premium UI** — Glassmorphism cards, gradient accents, micro-animations, and Lottie empty states
- **Category Management** — Organize items by customizable categories with pill-shaped chips
- **Price Tracking** — Log and visualize prices with charts powered by `fl_chart`
- **Shimmer Loading** — Skeleton loading placeholders while data loads
- **Haptic Feedback** — Tactile feedback on key interactions

## 🚀 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Riverpod (`flutter_riverpod`) |
| Local Storage | Hive (`hive_flutter`) |
| Routing | GoRouter |
| Scanning | Mobile Scanner, Google MLKit |
| Charts | fl_chart |
| Animations | Lottie, Flutter Animate, Shimmer |
| Typography | Google Fonts (Poppins, Inter) |

## 📱 Screens

- **Home Dashboard** — Summary cards with horizontal scroll, recent lists, and quick stats
- **Shopping Lists** — All your lists with staggered animations and hero transitions to detail
- **Scanner** — Barcode & OCR scanner for quick item entry
- **Cart Detail** — Per-list view with item management, toggling, and price tracking
- **Categories** — Manage and organize product categories
- **Settings** — Theme toggle, data management, and app preferences

## 🏗️ Getting Started

### Prerequisites

- Flutter SDK >=3.0.0
- Dart SDK >=3.0.0

### Installation

```bash
git clone https://github.com/Daymrens/BuyWMe.git
cd BuyWMe
flutter pub get
flutter run
```

### Build

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Linux
flutter build linux
```

## 📄 License

This project is private and not licensed for public use.
