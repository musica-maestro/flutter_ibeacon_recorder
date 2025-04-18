# Flutter iBeacon Recorder

A cross-platform Flutter application for recording indoor positioning data using iBeacon technology. This application is designed to collect and store positioning data for points of interest (POIs) in indoor environments, such as museums, galleries, or any indoor space requiring location-based services.

## Project Scope

This project enables:

- Detection and recording of iBeacon signal data
- Collection of RSSI (Received Signal Strength Indicator) values
- Tracking of beacon proximity and accuracy measurements
- Storage of collected data in MongoDB
- Support for both stationary and path-based recordings
- Integration with artwork/POI metadata

## Configuration Requirements

Before using this application, you need to configure the following:

### 1. MongoDB Configuration

Update the MongoDB connection details in `lib/services/mongo_service.dart`:

```dart
static const String _uri = 'mongodb+srv://yourusername:yourpassword@yourcluster.mongodb.net/?retryWrites=true&w=majority&appName=yourAppName';
```

Replace with your own MongoDB connection string.

### 2. iBeacon Configuration

Modify the iBeacon UUID in `lib/services/beacon_service.dart` to match your iBeacon deployment:

```dart
Region(
  identifier: 'your-identifier',
  proximityUUID: "your-uuid-here",
)
```

### 3. Points of Interest Data

Customize the `assets/artworks.jsonl` file with your own points of interest data. The current format supports artwork information, but you can adapt it for other POI types with minimal changes:

```json
{ "id": "POI_ID", "title": "POI Title", "location": "POI Location", "room": "Room Number" }
```

## Customization for Other POI Types

The application is currently configured for artworks as points of interest, but it can be easily adapted for:

- Retail store sections
- Conference room locations
- Educational institution spaces
- Any other indoor location requiring positioning data

Simply modify the data structure in `assets/artworks.jsonl` to match your POI requirements.

## Getting Started

1. Clone the repository
2. Configure MongoDB, iBeacon UUIDs, and POI data as described above
3. Run `flutter pub get` to install dependencies
4. Launch the application on an iOS or Android device

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

Users of this application are required to cite the original work in any derivative projects, publications, or research that makes use of this code or data collection methodology. Proper attribution details will be added in the future.
