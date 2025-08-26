import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/etappe.dart';

class StaticRouteMapWidget extends StatefulWidget {
  final Etappe etappe;
  final double height;
  final bool showFullscreen;

  const StaticRouteMapWidget({
    Key? key,
    required this.etappe,
    this.height = 300,
    this.showFullscreen = false,
  }) : super(key: key);

  @override
  _StaticRouteMapWidgetState createState() => _StaticRouteMapWidgetState();
}

class _StaticRouteMapWidgetState extends State<StaticRouteMapWidget> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Nach dem Laden zur Route zentrieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitRouteInView();
    });
  }

  void _fitRouteInView() {
    final routePoints = _getRoutePoints();
    if (routePoints.isEmpty) return;

    // Berechne Bounding Box der Route
    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (final point in routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Berechne Zentrum und Zoom
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    // Zoom basierend auf der Ausdehnung der Route
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    double zoom = 15.0; // Standard-Zoom
    if (maxDiff > 0.01) zoom = 12.0; // ~1km
    if (maxDiff > 0.05) zoom = 10.0; // ~5km
    if (maxDiff > 0.1) zoom = 9.0; // ~10km
    if (maxDiff > 0.5) zoom = 7.0; // ~50km

    _mapController.move(center, zoom);
  }

  void _zoomIn() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom - 1);
  }

  void _resetView() {
    _fitRouteInView();
  }

  List<LatLng> _getRoutePoints() {
    return widget.etappe.gpsPunkte
        .map((gpsPoint) => LatLng(gpsPoint.latitude, gpsPoint.longitude))
        .toList();
  }

  List<Polyline> _buildRoutePolylines() {
    final allPoints = widget.etappe.gpsPunkte;
    if (allPoints.isEmpty) return [];

    List<Polyline> polylines = [];
    List<LatLng> currentSegment = [];
    bool inInterpolatedSection = false;

    for (int i = 0; i < allPoints.length; i++) {
      final point = allPoints[i];
      final latLng = LatLng(point.latitude, point.longitude);

      // Prüfe ob Punkt interpoliert ist (accuracy = 999.0)
      final isInterpolated = point.accuracy != null && point.accuracy! > 900;

      if (isInterpolated && !inInterpolatedSection) {
        // Start einer interpolierten Sektion
        if (currentSegment.isNotEmpty) {
          // Beende aktuelles Segment (echte GPS-Punkte)
          polylines.add(Polyline(
            points: List.from(currentSegment),
            strokeWidth: 4.0,
            color: const Color(0xFF5A7D7D),
          ));
          currentSegment.clear();
        }
        inInterpolatedSection = true;
        currentSegment.add(latLng);
      } else if (!isInterpolated && inInterpolatedSection) {
        // Ende einer interpolierten Sektion
        currentSegment.add(latLng);
        // Erstelle gestrichelte Linie für interpolierte Sektion
        polylines.add(Polyline(
          points: List.from(currentSegment),
          strokeWidth: 3.0,
          color: const Color(0xFF5A7D7D).withOpacity(0.6),
          isDotted: true,
        ));
        currentSegment.clear();
        currentSegment.add(latLng);
        inInterpolatedSection = false;
      } else {
        // Normaler Punkt
        currentSegment.add(latLng);
      }
    }

    // Letztes Segment hinzufügen
    if (currentSegment.isNotEmpty) {
      polylines.add(Polyline(
        points: currentSegment,
        strokeWidth: inInterpolatedSection ? 3.0 : 4.0,
        color: inInterpolatedSection
            ? const Color(0xFF5A7D7D).withOpacity(0.6)
            : const Color(0xFF5A7D7D),
        isDotted: inInterpolatedSection,
      ));
    }

    return polylines;
  }

  LatLng? _getStartPosition() {
    if (widget.etappe.gpsPunkte.isEmpty) return null;
    final firstPoint = widget.etappe.gpsPunkte.first;
    return LatLng(firstPoint.latitude, firstPoint.longitude);
  }

  LatLng? _getEndPosition() {
    if (widget.etappe.gpsPunkte.isEmpty) return null;
    final lastPoint = widget.etappe.gpsPunkte.last;
    return LatLng(lastPoint.latitude, lastPoint.longitude);
  }

  String _getRouteInfo() {
    final distance = widget.etappe.formatierteDistanz;
    final duration = widget.etappe.formatierteDauer;
    return '$distance • $duration';
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = _getRoutePoints();

    // Fallback wenn keine GPS-Daten vorhanden
    if (routePoints.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade50,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Keine GPS-Daten verfügbar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Diese Etappe wurde ohne GPS-Aufzeichnung erstellt',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Standard-Position für Initialisierung
    LatLng center = routePoints.first;

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
                initialZoom: 15.0,
                minZoom: 3.0,
                maxZoom: 18.0,
              ),
              children: [
                // OpenStreetMap Tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.meinweg',
                  maxZoom: 18,
                ),

                // Route als Polyline mit GPS-Lücken-Visualisierung
                PolylineLayer(
                  polylines: _buildRoutePolylines(),
                ),

                // Marker für Start und Ende
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
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),

                    // End-Marker
                    if (_getEndPosition() != null &&
                        _getStartPosition() != _getEndPosition())
                      Marker(
                        point: _getEndPosition()!,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.stop,
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
                      heroTag: "fullscreen_static",
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5A7D7D),
                      onPressed: () {
                        _showFullscreenMap(context);
                      },
                      child: const Icon(Icons.fullscreen, size: 20),
                    ),

                  const SizedBox(height: 4),

                  // Fit Route Button
                  FloatingActionButton(
                    mini: true,
                    heroTag: "fit_route",
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5A7D7D),
                    onPressed: _resetView,
                    child: const Icon(Icons.center_focus_strong, size: 20),
                  ),

                  const SizedBox(height: 4),

                  // Zoom In
                  FloatingActionButton(
                    mini: true,
                    heroTag: "zoomIn_static",
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5A7D7D),
                    onPressed: _zoomIn,
                    child: const Icon(Icons.add, size: 20),
                  ),

                  const SizedBox(height: 4),

                  // Zoom Out
                  FloatingActionButton(
                    mini: true,
                    heroTag: "zoomOut_static",
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5A7D7D),
                    onPressed: _zoomOut,
                    child: const Icon(Icons.remove, size: 20),
                  ),
                ],
              ),
            ),

            // Route-Info oben links
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5A7D7D),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getRouteInfo(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // OpenStreetMap Attribution unten links
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'OpenStreetMap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

            // GPS-Legende unten rechts
            Positioned(
              bottom: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // GPS-Legende (nur wenn interpolierte Punkte vorhanden)
                  if (_hasInterpolatedPoints())
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 2,
                                color: const Color(0xFF5A7D7D),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'GPS',
                                style:
                                    TextStyle(color: Colors.white, fontSize: 8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 2,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF5A7D7D).withOpacity(0.6),
                                ),
                                child: CustomPaint(
                                  painter: DottedLinePainter(),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Geschätzt',
                                style:
                                    TextStyle(color: Colors.white, fontSize: 8),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Etappen-Status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.etappe.status == EtappenStatus.abgeschlossen
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.etappe.status == EtappenStatus.abgeschlossen
                          ? 'ABGESCHLOSSEN'
                          : widget.etappe.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasInterpolatedPoints() {
    return widget.etappe.gpsPunkte
        .any((point) => point.accuracy != null && point.accuracy! > 900);
  }

  void _showFullscreenMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Route: ${widget.etappe.name}'),
            backgroundColor: const Color(0xFF5A7D7D),
            foregroundColor: Colors.white,
          ),
          body: StaticRouteMapWidget(
            etappe: widget.etappe,
            height: double.infinity,
            showFullscreen: true,
          ),
        ),
      ),
    );
  }
}

// Custom Painter für gestrichelte Linie in der Legende
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5A7D7D).withOpacity(0.6)
      ..strokeWidth = 1;

    const dashWidth = 2.0;
    const dashSpace = 1.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
