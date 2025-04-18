import 'package:flutter/material.dart';
import 'package:flutter_ibeacon_recorder/models/artwork.dart';

class RecordingInProgressView extends StatelessWidget {
  final Artwork artwork;
  final bool isRecording;
  final String elapsedTime;
  final double recordingProgress;
  final VoidCallback onChangeArtwork;
  final VoidCallback onToggleRecording;

  const RecordingInProgressView({
    super.key,
    required this.artwork,
    required this.isRecording,
    required this.elapsedTime,
    required this.recordingProgress,
    required this.onChangeArtwork,
    required this.onToggleRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/pictures/${artwork.id}/url_1.jpg',
                    height: 200,
                    fit: BoxFit.fitHeight,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 48),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  artwork.displayTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (artwork.room != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.room, size: 20),
                      Text(
                        artwork.room!,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  artwork.authorName,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        if (isRecording) ...[
          const Spacer(),
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: recordingProgress,
                    strokeWidth: 2,
                  ),
                  Text(
                    elapsedTime,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Recording in Progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const Spacer(),
        ],
        if (!isRecording)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextButton(
                    onPressed: onChangeArtwork,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Change Artwork'),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: FilledButton(
                    onPressed: onToggleRecording,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Start Recording'),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
