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
  DateTime? _lastMapUpdate;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(LiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Batterie-Optimierung: Limitiere Map-Updates auf max. alle 3 Sekunden
    final now = DateTime.now();
    if (_lastMapUpdate != null &&
        now.difference(_lastMapUpdate!).inSeconds < 3) {
      return;
    }

    // Automatisch zur aktuellen Position zentrieren wenn Follow-Modus aktiv ist
    if (_isFollowingUser &&
        widget.trackingData?.currentPosition != null &&
        widget.trackingData != oldWidget.trackingData) {
      _centerOnCurrentPosition();
      _lastMapUpdate = now;
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

    final allPoints = widget.trackingData!.gpsPoints
        .map((gpsPoint) => LatLng(gpsPoint.latitude, gpsPoint.longitude))
        .toList();

    // Performance-Optimierung: Reduziere Punkte bei langen Routen
    return _optimizeRoutePoints(allPoints);
  }

  // Optimiert GPS-Punkte für bessere Performance
  List<LatLng> _optimizeRoutePoints(List<LatLng> points) {
    if (points.length <= 100) {
      return points; // Kleine Routen brauchen keine Optimierung
    }

    final optimized = <LatLng>[];
    const double minDistance = 5.0; // Mindestabstand in Metern

    optimized.add(points.first); // Startpunkt immer behalten

    for (int i = 1; i < points.length - 1; i++) {
      final lastPoint = optimized.last;
      final currentPoint = points[i];

      // Berechne Distanz zum letzten behaltenen Punkt
      final distance =
          const Distance().as(LengthUnit.Meter, lastPoint, currentPoint);

      // Nur Punkte behalten die weit genug entfernt sind
      if (distance >= minDistance) {
        optimized.add(currentPoint);
      }
    }

    if (points.isNotEmpty) {
      optimized.add(points.last); // Endpunkt immer behalten
    }

    print('Route optimiert: ${points.length} -> ${optimized.length} Punkte');
    return optimized;
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
                // OpenStreetMap Tiles mit Fehlerbehandlung
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.meinweg',
                  maxZoom: 18,
                  // Fallback für Offline-Nutzung
                  fallbackUrl:
                      'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // Tile-Loading-Optimierung
                  tileProvider: NetworkTileProvider(),
                  // Fehlerbehandlung
                  errorTileCallback: (tile, error, stackTrace) {
                    print('Map-Tile-Fehler: $error');
                  },
                ),

                // Route als Polyline mit Glättung
                if (_getRoutePoints().isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _getRoutePoints(),
                        strokeWidth: 4.0,
                        color: Color(0xFF5A7D7D),
                        // Verbesserte Darstellung
                        borderStrokeWidth: 2.0,
                        borderColor: Colors.white.withOpacity(0.8),
                        // Glatte Linien
                        useStrokeWidthInMeter: false,
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

                    // Aktuelle Position Marker mit Pulseffekt
                    if (_getCurrentPosition() != null)
                      Marker(
                        point: _getCurrentPosition()!,
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulsierender Hintergrund
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(0xFF5A7D7D).withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Hauptmarker
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(0xFF5A7D7D),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ],
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

            // Erweiterte Route-Info oben links
            if (_getRoutePoints().isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF5A7D7D).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.route,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Live-Route (${_getRoutePoints().length} Punkte)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
