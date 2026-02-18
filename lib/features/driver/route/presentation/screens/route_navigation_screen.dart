import 'dart:async';
import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:msaratwasel_services/core/presentation/widgets/custom_menu_button.dart';
import 'package:msaratwasel_services/core/presentation/widgets/glass_card.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_button.dart';

// Mock Data Model for Simulation
class StudentStop {
  final String nameAr;
  final String nameEn;
  final String parentAr;
  final String parentEn;
  final LatLng location;
  final bool isAbsent;
  final String photoUrl;

  const StudentStop({
    required this.nameAr,
    required this.nameEn,
    required this.parentAr,
    required this.parentEn,
    required this.location,
    required this.photoUrl,
    this.isAbsent = false,
  });
}

class RouteNavigationScreen extends StatefulWidget {
  const RouteNavigationScreen({super.key});

  @override
  State<RouteNavigationScreen> createState() => _RouteNavigationScreenState();
}

class _RouteNavigationScreenState extends State<RouteNavigationScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // Optimized Start Position: Al Mouj/Seeb (West of Azaiba) for linear flow
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(23.6264, 58.2618), // Al Mouj Area
    zoom: 13.0,
  );

  // Simulation Data (Optimized Linear Route: West -> East)
  final List<StudentStop> _stops = [
    const StudentStop(
      nameAr: 'أحمد سعيد',
      nameEn: 'Ahmed Saeed',
      parentAr: 'سعيد العلوي',
      parentEn: 'Saeed Al-Alawi',
      location: LatLng(23.6000, 58.3500), // Stop 1: Azaiba North
      photoUrl:
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=200',
    ),
    const StudentStop(
      nameAr: 'سارة محمد',
      nameEn: 'Sara Mohammed',
      parentAr: 'محمد الكندي',
      parentEn: 'Mohammed Al-Kindi',
      location: LatLng(23.5900, 58.4000), // Stop 2: Al Ghubra
      isAbsent: true,
      photoUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
    ),
    const StudentStop(
      nameAr: 'عمر خالد',
      nameEn: 'Omar Khaled',
      parentAr: 'خالد المعولي',
      parentEn: 'Khaled Al-Maawali',
      location: LatLng(23.6000, 58.4300), // Stop 3: Al Khuwair 33
      photoUrl:
          'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=200',
    ),
    const StudentStop(
      nameAr: 'ليلى البلوشي',
      nameEn: 'Layla Al-Balushi',
      parentAr: 'ياسر البلوشي',
      parentEn: 'Yasser Al-Balushi',
      location: LatLng(23.6080, 58.4500), // Stop 4: MSQ
      photoUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    ),
  ];

  int _currentStopIndex = 0;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isArrived = false;

  @override
  void initState() {
    super.initState();
    _initMapData();
  }

  // Manually defined points to strictly follow 18th Nov St & Sultan Qaboos St (Asphalt)
  // UPDATED: High-density points with specific Al Ghubra fix (Way 4293)
  List<LatLng> _getMuscatRoutePoints() {
    return [
      // 1. Start: Al Mouj Street (Asphalt)
      const LatLng(23.6264, 58.2618),
      const LatLng(23.6245, 58.2625),
      const LatLng(23.6230, 58.2630), // Roundabout
      // 2. 18th November Street (Main Highway - Eastbound)
      const LatLng(23.6190, 58.2690),
      const LatLng(23.6170, 58.2750),
      const LatLng(23.6150, 58.2850),
      const LatLng(23.6130, 58.2950),
      const LatLng(23.6110, 58.3050),
      const LatLng(23.6090, 58.3150),
      const LatLng(23.6070, 58.3250),
      const LatLng(23.6050, 58.3350),

      // 3. Turn into Azaiba North (Smooth Curve)
      const LatLng(23.6042, 58.3410),
      const LatLng(23.6035, 58.3430),
      const LatLng(23.6030, 58.3450),
      const LatLng(23.6015, 58.3470),
      const LatLng(23.6000, 58.3500), // Stop 1: Azaiba North
      // 4. Return to 18th Nov St (Retracing)
      const LatLng(23.6015, 58.3470),
      const LatLng(23.6030, 58.3450),
      const LatLng(23.6025, 58.3510),
      const LatLng(23.6000, 58.3550),
      const LatLng(23.5980, 58.3650),
      const LatLng(23.5960, 58.3750),
      const LatLng(23.5940, 58.3850),

      // 5. Turn into Ghubra (FIXED: Avoiding Haitham Jaffer Building)
      const LatLng(23.5935, 58.3880), // Arriving at junction
      const LatLng(23.5938, 58.3910), // Continue East slightly
      const LatLng(23.5930, 58.3930), // Turn Right into Way 4293
      const LatLng(23.5915, 58.3938), // South down the street
      const LatLng(23.5900, 58.3945), // Stop 2: Al Ghubra
      // 6. Navigate to Sultan Qaboos St (Complex Intersection)
      const LatLng(23.5895, 58.3960),
      const LatLng(23.5890, 58.3980),
      const LatLng(23.5880, 58.3950),
      const LatLng(23.5865, 58.3935), // Grand Mosque Roundabout
      const LatLng(23.5850, 58.3920),

      // 7. Sultan Qaboos St (Eastbound Highway - Smooth)
      const LatLng(23.5855, 58.3980),
      const LatLng(23.5860, 58.4050),
      const LatLng(23.5865, 58.4100),
      const LatLng(23.5872, 58.4125),
      const LatLng(23.5880, 58.4150),
      const LatLng(23.5888, 58.4180),
      const LatLng(23.5895, 58.4200),

      // 8. Exit to Al Khuwair (Dohat Al Adab St - Winding)
      const LatLng(23.5905, 58.4215), // Ramp Start
      const LatLng(23.5915, 58.4225),
      const LatLng(23.5925, 58.4235),
      const LatLng(23.5935, 58.4245),
      const LatLng(23.5945, 58.4255), // Thaqafah St
      const LatLng(23.5960, 58.4265),
      const LatLng(23.5975, 58.4275), // Passing Court Complex
      const LatLng(23.5990, 58.4285),
      const LatLng(23.6000, 58.4300), // Stop 3: Al Khuwair 33
      // 9. Continue via Service Roads to MSQ
      const LatLng(23.6005, 58.4310),
      const LatLng(23.6012, 58.4325),
      const LatLng(23.6020, 58.4350),
      const LatLng(23.6028, 58.4370), // Curve
      const LatLng(23.6035, 58.4385),
      const LatLng(23.6040, 58.4400),
      const LatLng(23.6048, 58.4415),
      const LatLng(23.6055, 58.4430),
      const LatLng(23.6062, 58.4445),
      const LatLng(23.6070, 58.4460),
      const LatLng(23.6078, 58.4480), // Turning into MSQ
      const LatLng(23.6080, 58.4500), // Stop 4: MSQ
    ];
  }

  void _initMapData() {
    _markers = _stops.asMap().entries.map((entry) {
      final index = entry.key;
      final stop = entry.value;
      final isNext = index == _currentStopIndex;
      final isCompleted = index < _currentStopIndex;

      // Ensure the marker always shows the name in the info window
      return Marker(
        markerId: MarkerId('stop_$index'),
        position: stop.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isCompleted
              ? BitmapDescriptor.hueGreen
              : isNext
              ? BitmapDescriptor.hueRed
              : BitmapDescriptor.hueAzure,
        ),
        infoWindow: InfoWindow(
          title: stop.nameAr,
          snippet: isNext ? 'الوجهة الحالية' : 'محطة ${index + 1}',
        ),
      );
    }).toSet();

    // Use our realistic points instead of just the stops
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route_line'),
        points: _getMuscatRoutePoints(),
        color: Colors.blue,
        width: 6,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Future<void> _advanceToNextStop() async {
    if (_currentStopIndex < _stops.length - 1) {
      setState(() {
        _currentStopIndex++;
        _isArrived = false;
        _initMapData(); // Refresh markers color
      });

      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _stops[_currentStopIndex].location, zoom: 15),
        ),
      );

      // Auto-show info window for the new target
      controller.showMarkerInfoWindow(MarkerId('stop_$_currentStopIndex'));
    } else {
      // End of route
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('انتهت الرحلة! جميع الطلاب وصلوا.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final currentStop = _currentStopIndex < _stops.length
        ? _stops[_currentStopIndex]
        : null;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map Background
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kInitialPosition,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              // Show the first stop's name immediately
              Future.delayed(const Duration(milliseconds: 500), () {
                controller.showMarkerInfoWindow(const MarkerId('stop_0'));
              });
            },
          ),

          // 2. Next Stop Card (Centered Adaptive Pill)
          if (currentStop != null)
            Positioned(
              top: 60, // Moved back to top as requested
              left: 20,
              right: 20,
              child: Align(
                alignment: Alignment.topCenter,
                child: IntrinsicWidth(
                  // Adapts width to content
                  child: _NextStopCard(isArabic: isArabic, stop: currentStop),
                ),
              ),
            ),

          // 3. Bottom Action Panel
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Route Info Pill
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              PhosphorIconsFill.clock,
                              size: 18,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "25 min",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 24),
                            const Icon(
                              PhosphorIconsFill.path,
                              size: 18,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "18 km",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().slideY(begin: 1, end: 0, duration: 400.ms),
                  const SizedBox(height: 20),

                  // Main Action Button (PremiumButton)
                  PremiumButton(
                    text: _isArrived
                        ? (isArabic ? '✅ الوجهة التالية' : 'Next Destination')
                        : (isArabic
                              ? '📍 الوصول للطالب'
                              : '📍 Arrive at Student'),
                    onTap: () {
                      if (_isArrived) {
                        _advanceToNextStop();
                      } else {
                        setState(() {
                          _isArrived = true;
                        });
                      }
                    },
                    icon: _isArrived
                        ? PhosphorIconsBold.arrowRight
                        : PhosphorIconsBold.mapPin,
                  ).animate().slideY(begin: 1, end: 0, duration: 500.ms),
                ],
              ),
            ),
          ),

          // 4. Top Bar (Back Button & Title) - MOVED TO END of Stack to be ON TOP
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(children: [CustomMenuButton()]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStopCard extends StatelessWidget {
  const _NextStopCard({required this.isArabic, required this.stop});

  final bool isArabic;
  final StudentStop stop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(12), // Reduced padding
          child: Row(
            children: [
              // Student Photo Avatar
              Container(
                padding: const EdgeInsets.all(2), // Reduced padding
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.2),
                      blurRadius: 10, // Reduced blur
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 26, // Reduced radius
                  backgroundImage: NetworkImage(stop.photoUrl),
                  onBackgroundImageError: (exception, stackTrace) =>
                      const Icon(Icons.person),
                ),
              ),
              const SizedBox(width: 14), // Reduced spacing
              // Info List
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, // Reduced horizontal padding
                          vertical: 3, // Reduced vertical padding
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isArabic ? 'الوجهة التالية' : 'Next Stop',
                          style: TextStyle(
                            fontSize: 11, // Reduced font size
                            color: Colors.amber[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ), // Replaced Spacer with fixed spacing
                      if (stop.isAbsent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            isArabic ? 'غياب محتمل' : 'Probable Absence',
                            style: const TextStyle(
                              fontSize: 9, // Reduced font size
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4), // Reduced spacing
                  Text(
                    isArabic ? stop.nameAr : stop.nameEn,
                    style: TextStyle(
                      fontSize: 18, // Reduced font size
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  // Guardian info removed
                ],
              ),
            ],
          ),
        )
        .animate(key: ValueKey(stop.nameEn))
        .fadeIn()
        .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
