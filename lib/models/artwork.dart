class Artwork {
  final String id;
  final String? title;
  final String? slug;
  final String? inventoryNumber;
  final List<String>? measurements;
  final String? dating;
  final String? location;
  final String? locationID;
  final List<String>? material;
  final String? provenance;
  final String? inscriptions;
  final String? historicalArtisticProfile;
  final String? rationalCaption;
  final List<Author>? authors;
  final String? room;

  Artwork({
    required this.id,
    this.title,
    this.slug,
    this.inventoryNumber,
    this.measurements,
    this.dating,
    this.location,
    this.locationID,
    this.material,
    this.provenance,
    this.inscriptions,
    this.historicalArtisticProfile,
    this.rationalCaption,
    this.authors,
    this.room,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      slug: json['slug'] as String?,
      inventoryNumber: json['inventoryNumber'] as String?,
      measurements: json['measurements'] != null
          ? List<String>.from(json['measurements'])
          : null,
      dating: json['dating'] as String?,
      location: json['location'] as String?,
      locationID: json['locationID'] as String?,
      material:
          json['material'] != null ? List<String>.from(json['material']) : null,
      provenance: json['provenance'] as String?,
      inscriptions: json['inscriptions'] as String?,
      historicalArtisticProfile: json['historicalArtisticProfile'] as String?,
      rationalCaption: json['rationalCaption'] as String?,
      authors: json['authors'] != null
          ? (json['authors'] as List)
              .map((author) => Author.fromJson(author))
              .toList()
          : null,
      room: json['room'] as String?,
    );
  }

  String get authorName {
    if (authors == null || authors!.isEmpty) return 'Unknown Artist';
    return authors!.first.author;
  }

  String get displayTitle {
    return title ?? 'Untitled';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'inventoryNumber': inventoryNumber,
      'measurements': measurements,
      'dating': dating,
      'location': location,
      'locationID': locationID,
      'material': material,
      'provenance': provenance,
      'inscriptions': inscriptions,
      'historicalArtisticProfile': historicalArtisticProfile,
      'rationalCaption': rationalCaption,
      'authors': authors?.map((author) => author.toJson()).toList(),
      'room': room,
    };
  }
}

class Author {
  final String author;
  final String? authorDate;

  Author({required this.author, this.authorDate});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      author: json['author'] as String? ?? 'Unknown',
      authorDate: json['authorDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'authorDate': authorDate,
    };
  }
}
