import 'package:flutter/material.dart';
import 'package:flutter_ibeacon_recorder/models/artwork.dart';
import 'package:flutter_ibeacon_recorder/services/artwork_service.dart';

class ArtworkSelectionView extends StatefulWidget {
  final Artwork? selectedArtwork;
  final Function(Artwork) onArtworkSelected;
  final ArtworkService artworkService;
  final String searchText;
  final Function(String)? onSearchChanged;

  const ArtworkSelectionView({
    super.key,
    required this.selectedArtwork,
    required this.onArtworkSelected,
    required this.artworkService,
    this.searchText = '',
    this.onSearchChanged,
  });

  @override
  State<ArtworkSelectionView> createState() => _ArtworkSelectionViewState();
}

class _ArtworkSelectionViewState extends State<ArtworkSelectionView> {
  late TextEditingController _searchController;
  bool _isLoading = true;
  List<Artwork> _artworks = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchText);
    _loadArtworks();
  }

  @override
  void didUpdateWidget(ArtworkSelectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchText != widget.searchText) {
      _searchController.text = widget.searchText;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArtworks() async {
    try {
      final artworks = await widget.artworkService.getArtworks();
      if (mounted) {
        setState(() {
          _artworks = artworks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading artworks: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredArtworks =
        widget.artworkService.searchArtworks(_searchController.text);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2.0, 4.0, 2.0, 16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by room, title, or artist...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey.shade900,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIconColor: Colors.grey.shade400,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              widget.onSearchChanged?.call(value);
              setState(() {});
            },
          ),
        ),
        Expanded(
          child: filteredArtworks.isEmpty
              ? Center(
                  child: Text(
                    'No artworks found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: filteredArtworks.length,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemBuilder: (context, index) {
                    final artwork = filteredArtworks[index];
                    final isSelected = widget.selectedArtwork?.id == artwork.id;

                    return Card(
                      elevation: isSelected ? 2 : 0,
                      margin: const EdgeInsets.only(bottom: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: isSelected
                            ? BorderSide(
                                color: Theme.of(context).primaryColor, width: 2)
                            : BorderSide(color: Colors.grey.shade200),
                      ),
                      child: InkWell(
                        onTap: () => widget.onArtworkSelected(artwork),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: Image.asset(
                                    'assets/pictures/${artwork.id}/url_1.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                            Icons.image_not_supported),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artwork.authorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (artwork.room != null)
                                      Row(
                                        children: [
                                          Icon(Icons.room,
                                              size: 14,
                                              color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              artwork.room!,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 2),
                                    Text(
                                      artwork.displayTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle,
                                    color: Theme.of(context).primaryColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
