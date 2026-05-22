import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/presentation/widgets/custom_menu_button.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_trip_entity.dart';
import 'package:msaratwasel_services/config/app_config.dart';

import '../cubit/bus_tracking_cubit.dart';
import '../../domain/entities/bus_position.dart';
import '../widgets/student_marker_widget.dart';
import 'package:msaratwasel_services/core/utils/location_utils.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/core/services/reverb_service.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/assistant/core/presentation/cubit/bus_trip_cubit.dart';

class BusMapScreen extends StatefulWidget {
  const BusMapScreen({super.key});

  @override
  State<BusMapScreen> createState() => _BusMapScreenState();
}

class _BusMapScreenState extends State<BusMapScreen> {
  bool _isDetailsExpanded = true;
  Timer? _pollingTimer;
  ReverbService? _reverbService;
  final GlobalKey<_TrackingMapState> _mapKey = GlobalKey<_TrackingMapState>();

  @override
  void initState() {
    super.initState();
    _startPolling();
    _initReverb();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        final cubit = context.read<BusTripCubit>();
        if (cubit.state is BusTripLoaded) {
          final trip = (cubit.state as BusTripLoaded).trip;
          if (trip.tripStatus == 'in_progress' ||
              trip.tripStatus == 'awaiting_video' ||
              trip.tripStatus == 'awaiting_confirmation') {
            cubit.loadTrip(silent: true);
          }
        }
      }
    });
  }

  void _initReverb() async {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final busId = user.busId;
      
      if (busId != null) {
        _reverbService = ReverbService(
          userId: int.tryParse(user.id) ?? 0,
          dio: ApiClient.instance,
          onMessageReceived: (data) {
            debugPrint('🔄 Trip status updated via Reverb inside BusMapScreen: $data');
            if (mounted) {
              context.read<BusTripCubit>().loadTrip(silent: true);
            }
          },
        );
        
        await _reverbService!.connect();
        await _reverbService!.subscribe('private-bus.$busId');
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _reverbService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<BusTripCubit, BusTripState>(
      listener: (context, state) {
        if (state is BusTripLoaded) {
          if (state.trip.tripStatus == 'finished' || state.trip.tripStatus == 'idle' || state.trip.tripStatus == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ لقد أنهى السائق الرحلة بنجاح. سيتم إعادتك للرئيسية.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            context.go(AppRoutes.assistantHome);
          } else {
            final trackingCubit = context.read<BusTrackingCubit>();
            if (trackingCubit.state is BusTrackingLoaded) {
              trackingCubit.updateStudents(List<BusStudentEntity>.from(state.trip.students));
            }
          }
        } else if (state is BusTripError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ تم إنهاء الرحلة أو حدث خطأ: ${state.message}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          context.go(AppRoutes.assistantHome);
        }
      },
      child: BlocProvider(
        create: (context) => BusTrackingCubit()..startTracking(),
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: BlocBuilder<BusTrackingCubit, BusTrackingState>(
                builder: (context, state) {
                // Error state
                if (state is BusTrackingError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            state.message,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton.icon(
                            onPressed: () => context.read<BusTrackingCubit>().startTracking(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(AppLocalizations.of(context)!.refresh),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Loading state
                if (state is! BusTrackingLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Loaded but no position yet — show waiting UI
                if (state.position == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'في انتظار بيانات الموقع...',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'لم يتم تسجيل موقع للحافلة بعد',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          OutlinedButton.icon(
                            onPressed: () => context.read<BusTrackingCubit>().startTracking(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l10n.refresh),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final tracking = state.position!;
                final students = state.students;
                final tripState = context.read<BusTripCubit>().state;
                final trip = tripState is BusTripLoaded ? tripState.trip : null;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: _TrackingMap(
                        key: _mapKey,
                        busPosition: tracking,
                        students: students,
                        trip: trip,
                        isDetailsExpanded: _isDetailsExpanded,
                      ),
                    ),
                    // Unified Premium Glassmorphic Top Bar Header
                    Positioned(
                      top: MediaQuery.of(context).padding.top + AppSpacing.md,
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? const Color(0xFF0F172A).withValues(alpha: 0.8) 
                                  : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.08) 
                                      : Colors.black.withValues(alpha: 0.05),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const CustomMenuButton(),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          trip != null 
                                              ? (trip.suggestedTripType == 'to_home' 
                                                  ? 'رحلة المساء (إلى المنزل)' 
                                                  : 'رحلة الصباح (إلى المدرسة)')
                                              : 'تتبع الحافلة',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        _StatusTextRow(
                                          state: tracking.state,
                                          l10n: l10n,
                                          theme: theme,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: _InteractiveRefreshButton(
                                      onTap: () {
                                        context.read<BusTripCubit>().loadTrip(silent: false);
                                        context.read<BusTrackingCubit>().startTracking();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Row(
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Text('جاري تحديث المسار والموقع...'),
                                              ],
                                            ),
                                            backgroundColor: Color(0xFF1A73E8),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            0,
                            AppSpacing.xl,
                            AppSpacing.xl,
                          ),
                          child: BlocBuilder<BusTripCubit, BusTripState>(
                            builder: (context, tripState) {
                              final trip = tripState is BusTripLoaded ? tripState.trip : null;
                              return _BottomDetailsCard(
                                position: tracking,
                                students: students,
                                l10n: l10n,
                                isOpen: _isDetailsExpanded,
                                onToggle: () => setState(
                                  () => _isDetailsExpanded = !_isDetailsExpanded,
                                ),
                                driverName: trip?.driverName ?? '-',
                                driverPhone: trip?.driverPhone ?? '-',
                                driverPhoto: trip?.driverPhoto,
                                onStopTap: (LatLng position) {
                                  _mapKey.currentState?._centerMapOnLatLng(position);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrackingMap extends StatefulWidget {
  final BusPosition busPosition;
  final List<BusStudentEntity> students;
  final BusTripEntity? trip;
  final bool isDetailsExpanded;

  const _TrackingMap({
    super.key,
    required this.busPosition,
    required this.students,
    this.trip,
    required this.isDetailsExpanded,
  });

  @override
  State<_TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<_TrackingMap> {
  final Map<String, BitmapDescriptor> _markers = {};
  GoogleMapController? _mapController;
  String? _lastRouteKey;
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;

  void _centerMapOnLatLng(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 16.5),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _fetchRouteIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _TrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.students != widget.students ||
        oldWidget.busPosition.lat != widget.busPosition.lat ||
        oldWidget.busPosition.lng != widget.busPosition.lng) {
      _loadMarkers();
    }
    _fetchRouteIfNeeded();
  }

  String _generateRouteKey() {
    final busLat = widget.busPosition.lat.toStringAsFixed(4);
    final busLng = widget.busPosition.lng.toStringAsFixed(4);
    final direction = widget.trip?.suggestedTripType ?? 'to_school';
    final studentIds = widget.students
        .map((s) => '${s.id}_${s.status.name}_${s.latitude ?? 0}')
        .join(',');
    return '$busLat,$busLng|$direction|$studentIds';
  }

  void _fetchRouteIfNeeded() {
    final newKey = _generateRouteKey();
    if (newKey == _lastRouteKey) return;
    _lastRouteKey = newKey;
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    if (_isFetchingRoute) return;
    _isFetchingRoute = true;

    final isToHome = widget.trip?.suggestedTripType == 'to_home';
    
    // Filter active students who are not absent and have valid coordinates
    final activeStudents = widget.students.where((student) {
      if (student.status == BusStudentStatus.absent) return false;
      
      final double? lat = isToHome
          ? (student.backLatitude ?? student.latitude ?? student.forthLatitude)
          : (student.forthLatitude ?? student.latitude ?? student.backLatitude);
      final double? lng = isToHome
          ? (student.backLongitude ?? student.longitude ?? student.forthLongitude)
          : (student.forthLongitude ?? student.longitude ?? student.backLongitude);
          
      return lat != null && lat != 0.0 && lng != null && lng != 0.0;
    }).toList();

    // Sort active students dynamically based on proximity (closest first)
    activeStudents.sort((a, b) {
      final locA = _getStudentLocation(a, isToHome);
      final locB = _getStudentLocation(b, isToHome);

      if (locA == null && locB == null) return 0;
      if (locA == null) return 1;
      if (locB == null) return -1;

      final distA = LocationUtils.calculateDistance(
        widget.busPosition.lat, 
        widget.busPosition.lng, 
        locA.latitude, 
        locA.longitude,
      );
      final distB = LocationUtils.calculateDistance(
        widget.busPosition.lat, 
        widget.busPosition.lng, 
        locB.latitude, 
        locB.longitude,
      );
      return distA.compareTo(distB);
    });

    LatLng? destination;

    if (isToHome) {
      // Afternoon trip: next destination is the first student not yet dropped at home
      BusStudentEntity? nextStudent;
      for (final s in activeStudents) {
        if (s.status != BusStudentStatus.atHome) {
          nextStudent = s;
          break;
        }
      }
      if (nextStudent != null) {
        destination = _getStudentLocation(nextStudent, isToHome);
      }
    } else {
      // Morning trip: next destination is first student not yet boarded and not yet dropped off at school
      BusStudentEntity? nextStudent;
      for (final s in activeStudents) {
        if (s.status != BusStudentStatus.onBus && s.status != BusStudentStatus.atSchool) {
          nextStudent = s;
          break;
        }
      }
      if (nextStudent != null) {
        destination = _getStudentLocation(nextStudent, isToHome);
      } else {
        // All active students have boarded. Destination is now the school!
        if (widget.trip?.schoolLatitude != null && widget.trip?.schoolLongitude != null &&
            widget.trip!.schoolLatitude != 0.0 && widget.trip!.schoolLongitude != 0.0) {
          destination = LatLng(widget.trip!.schoolLatitude!, widget.trip!.schoolLongitude!);
        }
      }
    }

    final origin = LatLng(widget.busPosition.lat, widget.busPosition.lng);

    if (destination == null) {
      if (mounted) {
        setState(() {
          _routePoints = [origin];
        });
      }
      _isFetchingRoute = false;
      return;
    }

    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=${AppConfig.googleMapsApiKey}';

      final dio = Dio();
      final response = await dio.get(url);

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final route = response.data['routes'][0];
        final points = _decodePolyline(route['overview_polyline']['points']);
        if (mounted) {
          setState(() {
            _routePoints = points;
          });
        }
      } else {
        debugPrint('⚠️ [Directions API] Error status: ${response.data['status']}');
        _setFallbackRoute(origin, destination);
      }
    } catch (e) {
      debugPrint('⚠️ [Directions API] Exception: $e');
      _setFallbackRoute(origin, destination);
    } finally {
      _isFetchingRoute = false;
    }
  }

  void _setFallbackRoute(LatLng origin, LatLng? destination) {
    if (!mounted) return;
    setState(() {
      _routePoints = [
        origin,
        // ignore: use_null_aware_elements
        if (destination != null) destination,
      ];
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  static LatLng? _getStudentLocation(BusStudentEntity student, bool isToHome) {
    final double? lat = isToHome
        ? (student.backLatitude ?? student.latitude ?? student.forthLatitude)
        : (student.forthLatitude ?? student.latitude ?? student.backLatitude);
    final double? lng = isToHome
        ? (student.backLongitude ?? student.longitude ?? student.forthLongitude)
        : (student.forthLongitude ?? student.longitude ?? student.backLongitude);
    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) return null;
    return LatLng(lat, lng);
  }

  Future<void> _loadMarkers() async {
    final langCode = Localizations.localeOf(context).languageCode;
    final isToHome = widget.trip?.suggestedTripType == 'to_home';

    // 1. Separate students into active, completed, and absent groups
    final activeStudents = <BusStudentEntity>[];
    for (final student in widget.students) {
      if (student.status != BusStudentStatus.absent) {
        final bool isCompleted = isToHome 
            ? (student.status == BusStudentStatus.atHome)
            : (student.status == BusStudentStatus.onBus || student.status == BusStudentStatus.atSchool);
        if (!isCompleted) {
          activeStudents.add(student);
        }
      }
    }

    // 2. Sort active students dynamically based on proximity (closest first)
    activeStudents.sort((a, b) {
      final locA = _getStudentLocation(a, isToHome);
      final locB = _getStudentLocation(b, isToHome);

      if (locA == null && locB == null) return 0;
      if (locA == null) return 1;
      if (locB == null) return -1;

      final distA = LocationUtils.calculateDistance(
        widget.busPosition.lat, 
        widget.busPosition.lng, 
        locA.latitude, 
        locA.longitude,
      );
      final distB = LocationUtils.calculateDistance(
        widget.busPosition.lat, 
        widget.busPosition.lng, 
        locB.latitude, 
        locB.longitude,
      );
      return distA.compareTo(distB);
    });

    final BusStudentEntity? nextStudent = activeStudents.isNotEmpty ? activeStudents.first : null;

    final newMarkers = <String, BitmapDescriptor>{};
    for (final student in widget.students) {
      try {
        final Color borderColor;
        final Color backgroundColor;
        final Color textColor;

        if (student.status == BusStudentStatus.absent) {
          borderColor = const Color(0xFFEF4444);
          backgroundColor = const Color(0xFFFEF2F2);
          textColor = const Color(0xFFEF4444);
        } else {
          final bool isCompleted = isToHome 
              ? (student.status == BusStudentStatus.atHome)
              : (student.status == BusStudentStatus.onBus || student.status == BusStudentStatus.atSchool);
          if (isCompleted) {
            borderColor = const Color(0xFF10B981);
            backgroundColor = const Color(0xFFF0FDF4);
            textColor = const Color(0xFF10B981);
          } else if (student.id == nextStudent?.id) {
            borderColor = const Color(0xFF3B82F6);
            backgroundColor = const Color(0xFFEFF6FF);
            textColor = const Color(0xFF3B82F6);
          } else {
            borderColor = const Color(0xFF94A3B8);
            backgroundColor = Colors.white;
            textColor = const Color(0xFF475569);
          }
        }

        final marker = await StudentMarkerWidget(
          name: student.getLocalizedName(langCode),
          imageUrl: student.photoUrl,
          borderColor: borderColor,
          backgroundColor: backgroundColor,
          textColor: textColor,
        ).toBitmapDescriptor(
          logicalSize: const Size(100, 100),
          imageSize: const Size(200, 200),
        );
        newMarkers[student.id] = marker;
      } catch (e) {
        newMarkers[student.id] = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final properMarkers = <Marker>{};
          for (final id in newMarkers.keys) {
            final student = widget.students.firstWhere((s) => s.id == id);
            final loc = _getStudentLocation(student, isToHome);
            if (loc != null) {
              properMarkers.add(Marker(
                markerId: MarkerId(id),
                position: loc,
              ));
            }
          }
          properMarkers.add(Marker(
            markerId: const MarkerId('bus_current'),
            position: LatLng(widget.busPosition.lat, widget.busPosition.lng),
          ));
          _fitBounds(properMarkers);
        }
      });
    }
  }

  void _fitBounds(Set<Marker> markers) {
    if (markers.isEmpty || _mapController == null) return;

    double? minLat, maxLat, minLng, maxLng;
    for (final m in markers) {
      if (minLat == null || m.position.latitude < minLat) {
        minLat = m.position.latitude;
      }
      if (maxLat == null || m.position.latitude > maxLat) {
        maxLat = m.position.latitude;
      }
      if (minLng == null || m.position.longitude < minLng) {
        minLng = m.position.longitude;
      }
      if (maxLng == null || m.position.longitude > maxLng) {
        maxLng = m.position.longitude;
      }
    }

    if (minLat != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng!),
            northeast: LatLng(maxLat!, maxLng!),
          ),
          100,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    markers.add(
      Marker(
        markerId: const MarkerId('bus_current'),
        position: LatLng(widget.busPosition.lat, widget.busPosition.lng),
        infoWindow: InfoWindow(title: widget.busPosition.busId),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    // Dynamic School Marker addition
    final schoolLat = widget.trip?.schoolLatitude;
    final schoolLng = widget.trip?.schoolLongitude;
    if (schoolLat != null && schoolLng != null && schoolLat != 0.0 && schoolLng != 0.0) {
      markers.add(
        Marker(
          markerId: const MarkerId('school_destination'),
          position: LatLng(schoolLat, schoolLng),
          infoWindow: const InfoWindow(title: 'المدرسة (الوجهة النهائية)'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    final langCode = Localizations.localeOf(context).languageCode;

    final isToHome = widget.trip?.suggestedTripType == 'to_home';

    for (var i = 0; i < widget.students.length; i++) {
      final student = widget.students[i];

      final loc = _getStudentLocation(student, isToHome);
      double lat = loc?.latitude ?? 0.0;
      double lng = loc?.longitude ?? 0.0;

      if (lat == 0.0 || lng == 0.0) {
        final double offset = (i % 2 == 0 ? 1 : -1) * (i * 0.00005);
        lat = widget.busPosition.lat + offset;
        lng = widget.busPosition.lng + offset;
      }

      final position = LatLng(lat, lng);

      markers.add(
        Marker(
          markerId: MarkerId('student_${student.id}'),
          position: position,
          infoWindow: InfoWindow(title: student.getLocalizedName(langCode)),
          icon: _markers[student.id] ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    if (_routePoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('blue_route'),
          points: _routePoints,
          color: const Color(0xFF1A73E8),
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.busPosition.lat, widget.busPosition.lng),
              zoom: 14,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: widget.isDetailsExpanded ? 490 : 160,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapControlButton(
                icon: Icons.my_location_rounded,
                tooltip: 'تركيز على الحافلة',
                onPressed: () {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(widget.busPosition.lat, widget.busPosition.lng),
                      16,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.map_rounded,
                tooltip: 'عرض المسار الكامل',
                onPressed: () => _fitBounds(markers),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomDetailsCard extends StatelessWidget {
  final BusPosition position;
  final List<BusStudentEntity> students;
  final AppLocalizations l10n;
  final bool isOpen;
  final VoidCallback onToggle;
  final String driverName;
  final String driverPhone;
  final String? driverPhoto;
  final Function(LatLng position)? onStopTap;

  const _BottomDetailsCard({
    required this.position,
    required this.students,
    required this.l10n,
    required this.isOpen,
    required this.onToggle,
    this.driverName = '-',
    this.driverPhone = '-',
    this.driverPhoto,
    this.onStopTap,
  });

  static String _formatUpdatedAt(DateTime updatedAt) {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inSeconds < 60) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} دقيقة';
    } else {
      return '${diff.inHours} ساعة';
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint('Could not launch phone call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final paddingBottom = MediaQuery.of(context).padding.bottom;

    final int totalStudents = students.length;
    final int absentCount = students
        .where((s) => s.status == BusStudentStatus.absent)
        .length;
    final int totalActive = totalStudents - absentCount;
    final int remainingCount =
        (totalStudents - absentCount - position.studentsOnBoard).clamp(0, 999);
    final double progress = totalActive > 0 ? (position.studentsOnBoard / totalActive) : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF0F172A).withValues(alpha: 0.85) 
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.08) 
                  : Colors.black.withValues(alpha: 0.04),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Elegant top accent gradient line
              Container(
                height: 4.5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
              
              // Drag Handle
              SizedBox(
                height: 14,
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                  ),
                ),
              ),

              // Driver Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                child: Row(
                  children: [
                    // Driver Avatar with nice gradient ring
                    Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        backgroundImage: driverPhoto != null
                            ? NetworkImage(driverPhoto!)
                            : null,
                        child: driverPhoto == null
                            ? Icon(Icons.person_rounded, size: 22, color: theme.colorScheme.primary)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  driverName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'سائق الحافلة',
                                  style: TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 8.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            driverPhone,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Elegant Call Button
                    if (driverPhone != '-' && driverPhone.isNotEmpty) ...[
                      Material(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _makePhoneCall(driverPhone),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.phone_in_talk_rounded,
                              color: Color(0xFF10B981),
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Toggle Button
                    Material(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : theme.colorScheme.primary.withValues(alpha: 0.06),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onToggle,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isOpen
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Expandable Body
              AnimatedCrossFade(
                firstChild: const SizedBox(height: 8),
                secondChild: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    10 + paddingBottom,
                  ),
                  child: Column(
                    children: [
                      // Progress Indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'نسبة ركوب الطلاب',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}% (${position.studentsOnBoard}/$totalActive)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Custom Gradient-filled animated progress bar
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              return Container(
                                height: 8,
                                width: width,
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.05) 
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOutCubic,
                                      width: width * progress,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // Stats row
                      Row(
                        children: [
                          _TrackingStat(
                            icon: Icons.groups_rounded,
                            label: l10n.remaining,
                            value: remainingCount.toString(),
                            accentColor: const Color(0xFF3B82F6),
                            bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                          ),
                          const SizedBox(width: 8),
                          _TrackingStat(
                            icon: Icons.directions_bus_rounded,
                            label: l10n.onBus,
                            value: position.studentsOnBoard.toString(),
                            accentColor: const Color(0xFFF59E0B),
                            bgColor: isDark ? const Color(0xFF2D251E) : const Color(0xFFFFF7ED),
                          ),
                          const SizedBox(width: 8),
                          _TrackingStat(
                            icon: Icons.person_off_rounded,
                            label: l10n.absent,
                            value: absentCount.toString(),
                            accentColor: const Color(0xFFEF4444),
                            bgColor: isDark ? const Color(0xFF361E1E) : const Color(0xFFFEF2F2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // ETA and Update Info in a beautifully structured row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_filled_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${l10n.remainingTime}: ${LocationUtils.formatEtaArabic(position.distanceKm)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${l10n.updated} ${_formatUpdatedAt(position.updatedAt)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Beautiful vertical stops and students timeline
                      _StopsTimeline(
                        students: students,
                        position: position,
                        tripType: context.read<BusTripCubit>().state is BusTripLoaded
                            ? (context.read<BusTripCubit>().state as BusTripLoaded).trip.suggestedTripType ?? 'to_school'
                            : 'to_school',
                        schoolLat: context.read<BusTripCubit>().state is BusTripLoaded
                            ? (context.read<BusTripCubit>().state as BusTripLoaded).trip.schoolLatitude
                            : null,
                        schoolLng: context.read<BusTripCubit>().state is BusTripLoaded
                            ? (context.read<BusTripCubit>().state as BusTripLoaded).trip.schoolLongitude
                            : null,
                        onStopTap: onStopTap,
                      ),
                    ],
                  ),
                ),
                crossFadeState: isOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.topCenter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color bgColor;

  const _TrackingStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        fontSize: 15,
                        height: 1.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        height: 1.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TimelineStopType {
  previous,
  current,
  upcoming,
  absent,
}

class _StopsTimeline extends StatelessWidget {
  final List<BusStudentEntity> students;
  final BusPosition position;
  final String tripType;
  final double? schoolLat;
  final double? schoolLng;
  final Function(LatLng position)? onStopTap;

  const _StopsTimeline({
    required this.students,
    required this.position,
    required this.tripType,
    this.schoolLat,
    this.schoolLng,
    this.onStopTap,
  });

  static LatLng? _getStudentLocation(BusStudentEntity student, bool isToHome) {
    final double? lat = isToHome
        ? (student.backLatitude ?? student.latitude ?? student.forthLatitude)
        : (student.forthLatitude ?? student.latitude ?? student.backLatitude);
    final double? lng = isToHome
        ? (student.backLongitude ?? student.longitude ?? student.forthLongitude)
        : (student.forthLongitude ?? student.longitude ?? student.backLongitude);
    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) return null;
    return LatLng(lat, lng);
  }

  static String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return 'تبعد ${distanceInMeters.round()} م';
    } else {
      final km = distanceInMeters / 1000;
      return 'تبعد ${km.toStringAsFixed(1)} كم';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isToHome = tripType == 'to_home';
    final langCode = Localizations.localeOf(context).languageCode;

    // 1. Separate students into active, completed, and absent groups
    final activeStudents = <BusStudentEntity>[];
    final completedStudents = <BusStudentEntity>[];
    final absentStudents = <BusStudentEntity>[];

    for (final student in students) {
      if (student.status == BusStudentStatus.absent) {
        absentStudents.add(student);
      } else {
        final bool isCompleted = isToHome 
            ? (student.status == BusStudentStatus.atHome)
            : (student.status == BusStudentStatus.onBus || student.status == BusStudentStatus.atSchool);
        if (isCompleted) {
          completedStudents.add(student);
        } else {
          activeStudents.add(student);
        }
      }
    }

    // 2. Sort active students dynamically based on proximity (closest first)
    activeStudents.sort((a, b) {
      final locA = _getStudentLocation(a, isToHome);
      final locB = _getStudentLocation(b, isToHome);

      if (locA == null && locB == null) return 0;
      if (locA == null) return 1; // Put students without location at the end of active list
      if (locB == null) return -1;

      final distA = LocationUtils.calculateDistance(position.lat, position.lng, locA.latitude, locA.longitude);
      final distB = LocationUtils.calculateDistance(position.lat, position.lng, locB.latitude, locB.longitude);
      return distA.compareTo(distB);
    });

    // 3. Combine sorted lists: Chronological Order (Completed/Previous stops first, then Active/Upcoming stops, then Absent ones)
    final sortedStudents = [...completedStudents, ...activeStudents, ...absentStudents];

    // Determine the active (next) target student stop
    final BusStudentEntity? nextStudent = activeStudents.isNotEmpty ? activeStudents.first : null;

    final bool allBoardedMorning = !isToHome && nextStudent == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(
                Icons.alt_route_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'خط السير ومحطات الطلاب',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 210),
          child: Scrollbar(
            thumbVisibility: true,
            interactive: true,
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(left: 8, right: 2),
              itemCount: sortedStudents.length + (schoolLat != null && schoolLat != 0.0 ? 1 : 0),
              itemBuilder: (context, index) {
                final isSchoolNode = index == sortedStudents.length;
                
                if (isSchoolNode) {
                  final bool isSchoolActive = allBoardedMorning;
                  final bool isSchoolFinished = isToHome;
                  
                  final _TimelineStopType schoolType = isSchoolFinished
                      ? _TimelineStopType.previous
                      : (isSchoolActive ? _TimelineStopType.current : _TimelineStopType.upcoming);

                  return _TimelineTile(
                    isFirst: false,
                    isLast: true,
                    type: schoolType,
                    title: 'المدرسة (الوجهة النهائية)',
                    subtitle: 'وصول الحافلة إلى مبنى المدرسة',
                    icon: Icons.school_rounded,
                    statusLabel: schoolType == _TimelineStopType.current 
                        ? 'المحطة الحالية 📍' 
                        : (schoolType == _TimelineStopType.previous ? 'وصلت الحافلة ✅' : 'في الانتظار ⏳'),
                    statusColor: schoolType == _TimelineStopType.current 
                        ? const Color(0xFF3B82F6) 
                        : (schoolType == _TimelineStopType.previous ? const Color(0xFF10B981) : Colors.grey),
                    isDark: isDark,
                    onTap: () {
                      if (schoolLat != null && schoolLng != null) {
                        onStopTap?.call(LatLng(schoolLat!, schoolLng!));
                      }
                    },
                  );
                }

                final student = sortedStudents[index];
                final isFirst = index == 0;
                final isLast = index == sortedStudents.length - 1 && (schoolLat == null || schoolLat == 0.0);
                
                final bool isCurrentTarget = student.id == nextStudent?.id;
                
                final _TimelineStopType stopType;
                if (student.status == BusStudentStatus.absent) {
                  stopType = _TimelineStopType.absent;
                } else {
                  final bool isCompleted = isToHome 
                      ? (student.status == BusStudentStatus.atHome)
                      : (student.status == BusStudentStatus.onBus || student.status == BusStudentStatus.atSchool);
                  if (isCompleted) {
                    stopType = _TimelineStopType.previous;
                  } else if (isCurrentTarget) {
                    stopType = _TimelineStopType.current;
                  } else {
                    stopType = _TimelineStopType.upcoming;
                  }
                }

                String statusLabel = 'محطة قادمة ⏳';
                Color statusColor = Colors.grey;
                IconData nodeIcon = Icons.person_pin_circle_rounded;

                switch (stopType) {
                  case _TimelineStopType.previous:
                    statusLabel = 'محطة سابقة ✅';
                    statusColor = const Color(0xFF10B981);
                    break;
                  case _TimelineStopType.current:
                    statusLabel = 'المحطة الحالية 📍';
                    statusColor = const Color(0xFF3B82F6);
                    break;
                  case _TimelineStopType.upcoming:
                    statusLabel = 'محطة قادمة ⏳';
                    statusColor = isDark ? Colors.white60 : Colors.grey.shade600;
                    break;
                  case _TimelineStopType.absent:
                    statusLabel = 'غائب 🛑';
                    statusColor = const Color(0xFFEF4444);
                    break;
                }

                switch (student.status) {
                  case BusStudentStatus.onBus:
                    nodeIcon = Icons.directions_bus_rounded;
                    break;
                  case BusStudentStatus.atSchool:
                    nodeIcon = Icons.school_rounded;
                    break;
                  case BusStudentStatus.atHome:
                    nodeIcon = Icons.home_rounded;
                    break;
                  case BusStudentStatus.absent:
                    nodeIcon = Icons.person_off_rounded;
                    break;
                  case BusStudentStatus.waiting:
                    nodeIcon = Icons.hourglass_empty_rounded;
                    break;
                  default:
                    nodeIcon = Icons.radio_button_unchecked_rounded;
                }

                String? distanceText;
                final loc = _getStudentLocation(student, isToHome);
                if (student.status != BusStudentStatus.absent && stopType != _TimelineStopType.previous && loc != null) {
                  final dist = LocationUtils.calculateDistance(position.lat, position.lng, loc.latitude, loc.longitude);
                  distanceText = _formatDistance(dist);
                }

                double lat = loc?.latitude ?? 0.0;
                double lng = loc?.longitude ?? 0.0;
                final studentPosition = LatLng(lat, lng);

                return _TimelineTile(
                  isFirst: isFirst,
                  isLast: isLast,
                  type: stopType,
                  title: student.getLocalizedName(langCode),
                  subtitle: student.getLocalizedGrade(langCode),
                  distanceText: distanceText,
                  icon: nodeIcon,
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                  isDark: isDark,
                  onTap: () {
                    if (lat != 0.0 && lng != 0.0) {
                      onStopTap?.call(studentPosition);
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final _TimelineStopType type;
  final String title;
  final String subtitle;
  final String? distanceText;
  final IconData icon;
  final String statusLabel;
  final Color statusColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _TimelineTile({
    required this.isFirst,
    required this.isLast,
    required this.type,
    required this.title,
    required this.subtitle,
    this.distanceText,
    required this.icon,
    required this.statusLabel,
    required this.statusColor,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = type == _TimelineStopType.current;
    final isCompleted = type == _TimelineStopType.previous;
    final isAbsent = type == _TimelineStopType.absent;

    // Line drawing logic for green trail up to the active stop (📍)
    final Color topLineColor = isFirst
        ? Colors.transparent
        : ((isCompleted || isActive)
            ? const Color(0xFF10B981)
            : theme.colorScheme.outline.withValues(alpha: 0.15));

    final Color bottomLineColor = isLast
        ? Colors.transparent
        : (isCompleted
            ? const Color(0xFF10B981)
            : theme.colorScheme.outline.withValues(alpha: 0.15));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2.2,
                    color: topLineColor,
                  ),
                ),
                isActive
                    ? _PulsingActiveIndicator(color: statusColor, icon: icon)
                    : Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : (isAbsent ? const Color(0xFFEF4444).withValues(alpha: 0.08) : Colors.transparent),
                          border: Border.all(
                            color: isCompleted
                               ? const Color(0xFF10B981)
                                : (isAbsent ? const Color(0xFFEF4444) : theme.colorScheme.outline.withValues(alpha: 0.3)),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 14,
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : (isAbsent ? const Color(0xFFEF4444) : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        ),
                      ),
                Expanded(
                  child: Container(
                    width: 2.2,
                    color: bottomLineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                        : (isCompleted
                            ? (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF0FDF4))
                            : (isAbsent
                                ? (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFFEF2F2))
                                : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50))),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.65)
                          : (isCompleted
                              ? const Color(0xFF10B981).withValues(alpha: 0.25)
                              : (isAbsent
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                                  : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)))),
                      width: isActive ? 1.8 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                                color: isActive 
                                    ? theme.colorScheme.primary 
                                    : (isAbsent 
                                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4) 
                                        : (isCompleted ? theme.colorScheme.onSurface.withValues(alpha: 0.8) : theme.colorScheme.onSurface)),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isAbsent 
                                        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                                        : (isCompleted ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5) : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (distanceText != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    distanceText!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isActive 
                                          ? theme.colorScheme.primary.withValues(alpha: 0.9)
                                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ADDITIONAL PREMIUM UI HELPER CLASSES
// ==========================================

class _StatusTextRow extends StatelessWidget {
  final BusState state;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _StatusTextRow({
    required this.state,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    Color color = Colors.green;
    String label = l10n.busStateEnRoute;

    switch (state) {
      case BusState.atStation:
        color = const Color(0xFFF59E0B);
        label = l10n.busStateAtStation;
        break;
      case BusState.enRoute:
        color = const Color(0xFF10B981);
        label = l10n.busStateEnRoute;
        break;
      case BusState.arrived:
        color = const Color(0xFF3B82F6);
        label = l10n.busStateArrived;
        break;
    }

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BreathingStatusDot(color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathingStatusDot extends StatefulWidget {
  final Color color;
  const _BreathingStatusDot({required this.color});

  @override
  State<_BreathingStatusDot> createState() => _BreathingStatusDotState();
}

class _BreathingStatusDotState extends State<_BreathingStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 3.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 3,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InteractiveRefreshButton extends StatefulWidget {
  final VoidCallback onTap;

  const _InteractiveRefreshButton({required this.onTap});

  @override
  State<_InteractiveRefreshButton> createState() => _InteractiveRefreshButtonState();
}

class _InteractiveRefreshButtonState extends State<_InteractiveRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    _controller.repeat();
    widget.onTap();
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _controller.stop();
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: 'تحديث البيانات',
        child: InkWell(
          onTap: _handleTap,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: RotationTransition(
              turns: _controller,
              child: Icon(
                Icons.refresh_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _MapControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: isDark 
                ? const Color(0xFF1E293B).withValues(alpha: 0.8) 
                : Colors.white.withValues(alpha: 0.85),
            child: InkWell(
              onTap: onPressed,
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.08),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.12) 
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingActiveIndicator extends StatefulWidget {
  final Color color;
  final IconData icon;

  const _PulsingActiveIndicator({
    required this.color,
    required this.icon,
  });

  @override
  State<_PulsingActiveIndicator> createState() => _PulsingActiveIndicatorState();
}

class _PulsingActiveIndicatorState extends State<_PulsingActiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 24 * _animation.value,
              height: 24 * _animation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.2 * (2.0 - _animation.value)),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.15),
                border: Border.all(
                  color: widget.color,
                  width: 2,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 14,
                color: widget.color,
              ),
            ),
          ],
        );
      },
    );
  }
}
