import 'package:flutter/material.dart';

class RecordingSummaryView extends StatelessWidget {
  final Map<String, dynamic> recordedData;
  final TextEditingController noteController;
  final String? selectedCrowdedness;
  final Function(String?) onCrowdednessChanged;
  final VoidCallback onDiscard;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  const RecordingSummaryView({
    super.key,
    required this.recordedData,
    required this.noteController,
    required this.selectedCrowdedness,
    required this.onCrowdednessChanged,
    required this.onDiscard,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (title == 'BLE Devices')
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '(${children.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (title == 'BLE Devices' && children.isNotEmpty)
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: children.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: children[index],
                );
              },
            ),
          )
        else
          ...children.map((child) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: child,
              )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recording Summary',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    title: 'Recording Details',
                    icon: Icons.info_outline,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCrowdedness,
                        decoration: InputDecoration(
                          labelText: 'Room crowdedness',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'empty (1 person)',
                              child: Text('Empty (1 person)')),
                          DropdownMenuItem(
                              value: 'sparse (2-5)',
                              child: Text('Sparse (2-5)')),
                          DropdownMenuItem(
                              value: 'moderate (5-10)',
                              child: Text('Moderate (5-10)')),
                          DropdownMenuItem(
                              value: 'crowded (>10)',
                              child: Text('Crowded (>10)')),
                        ],
                        onChanged: onCrowdednessChanged,
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: noteController,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoSection(
                    title: 'Sensor Data',
                    icon: Icons.sensors,
                    children: [
                      for (var entry
                          in (recordedData['sensorReadings']
                                  as Map<String, dynamic>)
                              .entries
                              .toList()
                            ..sort((a, b) => b.value.compareTo(a.value)))
                        Text(
                          '${entry.key.substring(0, 1).toUpperCase()}${entry.key.substring(1)}: ${entry.value} datapoints',
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoSection(
                    title: 'BLE Devices',
                    icon: Icons.bluetooth_searching,
                    children: (recordedData['bleReadings']
                                    as Map<String, dynamic>?)
                                ?.isEmpty ??
                            true
                        ? [const Text('No BLE devices detected')]
                        : (recordedData['bleReadings'] as Map<String, dynamic>)
                            .entries
                            .map<Widget>((entry) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Beacon ${entry.key}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'RSSI: ${entry.value['last_rssi']} dBm',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          'Count: ${entry.value['count']}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ))
                            .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextButton(
                  onPressed: onDiscard,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Discard'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: FilledButton(
                  onPressed: selectedCrowdedness != null && !isSubmitting
                      ? onSubmit
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit Recording'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
