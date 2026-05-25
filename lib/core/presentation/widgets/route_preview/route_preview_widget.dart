import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoutePreviewWidget extends StatefulWidget {
  final LatLng busLocation;
  final LatLng schoolLocation;
  final List<LatLng> studentLocations;

  const RoutePreviewWidget({
    super.key,
    required this.busLocation,
    required this.schoolLocation,
    required this.studentLocations,
  });

  @override
  State<RoutePreviewWidget> createState() => _RoutePreviewWidgetState();
}

class _RoutePreviewWidgetState extends State<RoutePreviewWidget> {
  // استخدام Map لتخزين العلامات ديناميكياً تماماً كما ورد في التوثيق المعطى
  final Map<String, Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _buildRouteElements();
  }

  void _buildRouteElements() {
    _markers.clear();

    // 1. إضافة علامة الحافلة (باللون الأزرق)
    _markers['bus'] = Marker(
      markerId: const MarkerId('bus_location'),
      position: widget.busLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'موقع الحافلة الحالي'),
    );

    // 2. إضافة علامة المدرسة (باللون الأحمر)
    _markers['school'] = Marker(
      markerId: const MarkerId('school_location'),
      position: widget.schoolLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'المدرسة'),
    );

    // 3. إضافة علامات منازل الطلاب ورسم نقاط الخط الملاحي
    List<LatLng> polylinePoints = [widget.busLocation];

    for (int i = 0; i < widget.studentLocations.length; i++) {
      final studentPos = widget.studentLocations[i];
      final String markerId = 'student_$i';
      
      _markers[markerId] = Marker(
        markerId: MarkerId(markerId),
        position: studentPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: 'نقطة توقف الطالب ${i + 1}'),
      );
      polylinePoints.add(studentPos);
    }

    polylinePoints.add(widget.schoolLocation);

    // 4. رسم الخط الملاحي الذكي الذي يربط خط السير بالكامل
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('bus_route_line'),
        points: polylinePoints,
        color: Colors.blue[700]!,
        width: 5,
        geodesic: true,
      ),
    );
  }

  // دالة مخصصة لعمل زوم تلقائي ذكي ليحتوي المشهد كامل النقاط فور الإقلاع
  void _zoomToFitRoute() {
    if (_markers.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;

    for (final marker in _markers.values) {
      if (minLat == null || marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (maxLat == null || marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (minLng == null || marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (maxLng == null || marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );

    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.busLocation,
          zoom: 12,
        ),
        markers: _markers.values.toSet(),
        polylines: _polylines,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          _zoomToFitRoute(); // تفعيل الزوم التلقائي التكيفي فور البناء
        },
        // إغلاق أدوات التحكم الإضافية للحفاظ على رشاقة التصميم داخل الكارد
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }
}
