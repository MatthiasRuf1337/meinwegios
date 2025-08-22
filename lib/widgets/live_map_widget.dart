import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/tracking_service_v2.dart';

class LiveMapWidget extends StatefulWidget {
  final TrackingData? trackingData;
  final double height;
  final bool showFullscreen;

  const LiveMapWidget({
    Key? key,
    this.trackingData,
    this.height = 300,
    this.showFullscreen = false,
  }) : super(key: key);

  @override
  _LiveMapWidgetState createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  final MapController _mapController = MapController();
  bool _isFollowingUser = true;
  LatLng? _lastCenter;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(LiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Automatisch zur aktuellen Position zentrieren wenn Follow-Modus aktiv ist
    if (_isFollowingUser &&
        widget.trackingData?.currentPosition != null &&
        widget.trackingData != oldWidget.trackingData) {
      _centerOnCurrentPosition();
    }
  }

  void _centerOnCurrentPosition() {
    if (widget.trackingData?.currentPosition != null) {
      final position = widget.trackingData!.currentPosition!;
      final newCenter = LatLng(position.latitude, position.longitude);

      // Nur bewegen wenn sich die Position signifikant geändert hat
      if (_lastCenter == null ||
          const Distance().as(LengthUnit.Meter, _lastCenter!, newCenter) > 10) {
        _mapController.move(newCenter, _mapController.camera.zoom);
        _lastCenter = newCenter;
      }
    }
  }

  void _toggleFollowMode() {
    setState(() {
      _isFollowingUser = !_isFollowingUser;
    });

    if (_isFollowingUser) {
      _centerOnCurrentPosition();
    }
  }

  void _zoomIn() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom - 1);
  }

  List<LatLng> _getRoutePoints() {
    if (widget.trackingData?.gpsPoints.isEmpty ?? true) {
      return [];
    }

    return widget.trackingData!.gpsPoints
        .map((gpsPoint) => LatLng(gpsPoint.latitude, gpsPoint.longitude))
        .toList();
  }

  LatLng? _getCurrentPosition() {
    if (widget.trackingData?.currentPosition == null) return null;
    final pos = widget.trackingData!.currentPosition!;
    return LatLng(pos.latitude, pos.longitude);
  }

  LatLng? _getStartPosition() {
    if (widget.trackingData?.gpsPoints.isEmpty ?? true) return null;
    final firstPoint = widget.trackingData!.gpsPoints.first;
    return LatLng(firstPoint.latitude, firstPoint.longitude);
  }

  @override
  Widget build(BuildContext context) {
    // Standard-Position (Deutschland) falls keine GPS-Daten vorhanden
    LatLng center = LatLng(51.1657, 10.4515); // Deutschland Zentrum
    double zoom = 6.0;

    // Verwende aktuelle Position falls verfügbar
    final currentPos = _getCurrentPosition();
    if (currentPos != null) {
      center = currentPos;
      zoom = 16.0;
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                minZoom: 3.0,
                maxZoom: 18.0,
                onMapReady: () {
                  // Nach dem Laden zur aktuellen Position zentrieren
                  if (_isFollowingUser) {
                    _centerOnCurrentPosition();
                  }
                },
                onPositionChanged: (position, hasGesture) {
                  // Follow-Modus deaktivieren wenn Nutzer manuell bewegt
                  if (hasGesture && _isFollowingUser) {
                    setState(() {
                      _isFollowingUser = false;
                    });
                  }
                },
              ),
              children: [
                // OpenStreetMap Tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.meinweg',
                  maxZoom: 18,
                ),

                // Route als Polyline
                if (_getRoutePoints().isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _getRoutePoints(),
                        strokeWidth: 4.0,
                        color: Color(0xFF5A7D7D),
                      ),
                    ],
                  ),

                // Marker
                MarkerLayer(
                  markers: [
                    // Start-Marker
                    if (_getStartPosition() != null)
                      Marker(
                        point: _getStartPosition()!,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),

                    // Aktuelle Position Marker
                    if (_getCurrentPosition() != null)
                      Marker(
                        point: _getCurrentPosition()!,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF5A7D7D),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Control-Buttons
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  // Fullscreen Button (nur wenn nicht bereits Fullscreen)
                  if (!widget.showFullscreen)
                    FloatingActionButton(
                      mini: true,
                      heroTag: "fullscreen",
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF5A7D7D),
                      onPressed: () {
                        _showFullscreenMap(context);
                      },
                      child: Icon(Icons.fullscreen, size: 20),
                    ),

                  SizedBox(height: 4),

                  // Follow-Button
                  FloatingActionButton(
                    mini: true,
                    heroTag: "follow",
                    backgroundColor:
                        _isFollowingUser ? Color(0xFF5A7D7D) : Colors.white,
                    foregroundColor:
                        _isFollowingUser ? Colors.white : Color(0xFF5A7D7D),
                    onPressed: _toggleFollowMode,
                    child: Icon(Icons.my_location, size: 20),
                  ),

                  SizedBox(height: 4),

                  // Zoom In
                  FloatingActionButton(
                    mini: true,
                    heroTag: "zoomIn",
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF5A7D7D),
                    onPressed: _zoomIn,
                    child: Icon(Icons.add, size: 20),
                  ),

                  SizedBox(height: 4),

                  // Zoom Out
                  FloatingActionButton(
                    mini: true,
                    heroTag: "zoomOut",
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF5A7D7D),
                    onPressed: _zoomOut,
                    child: Icon(Icons.remove, size: 20),
                  ),
                ],
              ),
            ),

            // Status-Info unten links
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'OpenStreetMap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

            // Route-Info oben links (GPS-Punkte entfernt für saubere Anzeige)
            if (_getRoutePoints().isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF5A7D7D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Live-Route',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Live-Karte'),
            backgroundColor: Color(0xFF5A7D7D),
            foregroundColor: Colors.white,
          ),
          body: LiveMapWidget(
            trackingData: widget.trackingData,
            height: double.infinity,
            showFullscreen: true,
          ),
        ),
      ),
    );
  }
}
