# PlatePal

PlatePal is a commissioned Flutter-based mobile application designed to help users plan their meals, search for recipes, and manage their dietary needs.

## Table of Contents
- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Technologies Used](#technologies-used)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Features

- Search recipes by name or ingredients
- View detailed recipe information including ingredients, instructions, and nutritional data
- Plan meals for the week
- User-friendly interface with intuitive navigation

## Getting Started

### Prerequisites

- Flutter SDK (version 3.5.0 or higher)
- Dart SDK (version 3.5.0 or higher)
- Android Studio or VS Code with Flutter and Dart plugins

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/KenPrz/platepal.git
   ```

2. Navigate to the project directory:
   ```
   cd platepal
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the app:
   ```
   flutter run
   ```

## Usage

- **Home Screen**: Navigate to different sections of the app
- **Search by Recipe**: Find recipes by name
- **Search by Ingredients**: Find recipes based on available ingredients
- **Meal Planner**: Plan your meals for the week

## Project Structure

```
platepal/
├── lib/
│   ├── components/
│   ├── models/
│   ├── pages/
│   ├── database_helper.dart
│   └── main.dart
├── assets/
│   ├── images/
│   ├── videos/
│   ├── icons/
│   ├── ingredients/
│   └── db/
├── android/
├── ios/
└── pubspec.yaml
```

## Technologies Used

- Flutter
- Dart
- SQLite (via sqflite package)
- flutter_svg for SVG rendering
- video_player and chewie for video playback

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgements

- App icon and design elements created for this project
- Special thanks to the Flutter and Dart communities for their excellent documentation and support

---

This project is commissioned work and is maintained at [https://github.com/KenPrz/platepal](https://github.com/KenPrz/platepal)