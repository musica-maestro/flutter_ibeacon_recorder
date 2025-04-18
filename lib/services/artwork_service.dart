import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ibeacon_recorder/models/artwork.dart';

class ArtworkService {
  static final ArtworkService _instance = ArtworkService._internal();
  factory ArtworkService() => _instance;
  ArtworkService._internal();

  List<Artwork> _artworks = [];
  bool _isInitialized = false;

  Future<List<Artwork>> getArtworks() async {
    if (!_isInitialized) {
      await _loadArtworks();
    }
    return _artworks;
  }

  Future<void> _loadArtworks() async {
    try {
      final String content =
          await rootBundle.loadString('assets/artworks.jsonl');
      final List<String> lines =
          content.split('\n').where((line) => line.isNotEmpty).toList();
      _artworks = await compute(_parseArtworks, lines);
      _isInitialized = true;
    } catch (e) {
      print('Error loading artworks: $e');
      rethrow;
    }
  }

  static List<Artwork> _parseArtworks(List<String> lines) {
    return lines
        .map((line) {
          try {
            return Artwork.fromJson(json.decode(line));
          } catch (e) {
            print('Error parsing artwork: $e');
            return null;
          }
        })
        .whereType<Artwork>()
        .toList();
  }

  List<Artwork> searchArtworks(String query) {
    if (query.isEmpty) return _artworks;

    final searchLower = query.toLowerCase();
    return _artworks
        .where((artwork) =>
            artwork.displayTitle.toLowerCase().contains(searchLower) ||
            artwork.authorName.toLowerCase().contains(searchLower) ||
            (artwork.room?.toLowerCase().contains(searchLower) ?? false))
        .toList();
  }
}
