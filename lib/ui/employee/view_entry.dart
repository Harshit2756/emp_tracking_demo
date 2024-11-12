import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ViewEntryPage extends StatelessWidget {
  final String time;
  final String? image;
  final double? lat;
  final double? lng;
  final bool isEntry;

  const ViewEntryPage({
    super.key,
    required this.time,
    this.image,
    this.lat,
    this.lng,
    required this.isEntry,
  });

  @override
  Widget build(BuildContext context) {
    final mapController = MapController();

    return Scaffold(
      appBar: AppBar(
        title: Text('${isEntry ? "Entry" : "Exit"} Details'),
        backgroundColor: isEntry ? Colors.teal : Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Time: $time',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (image != null)
              SizedBox(
                height: 300,
                width: double.infinity,
                child: Hero(
                  tag: 'entry_image_$time',
                  child: Image.memory(
                    base64Decode(image!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (lat != null && lng != null) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Location:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Stack(
                children: [
                  Container(
                    height: 200,
                    margin: const EdgeInsets.all(16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: LatLng(lat!, lng!),
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.yourapp.name',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(lat!, lng!),
                                width: 80,
                                height: 80,
                                child: Icon(
                                  Icons.location_on,
                                  color: isEntry ? Colors.teal : Colors.blue,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 24.0,
                    bottom: 24.0,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'zoom_in_$time',
                          onPressed: () {
                            final currentZoom = mapController.zoom;
                            mapController.move(
                                LatLng(lat!, lng!), currentZoom + 1);
                          },
                          backgroundColor: isEntry ? Colors.teal : Colors.blue,
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'zoom_out_$time',
                          onPressed: () {
                            final currentZoom = mapController.zoom;
                            mapController.move(
                                LatLng(lat!, lng!), currentZoom - 1);
                          },
                          backgroundColor: isEntry ? Colors.teal : Colors.blue,
                          child: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
