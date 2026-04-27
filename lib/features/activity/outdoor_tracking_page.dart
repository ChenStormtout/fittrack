import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../auth/controllers/auth_controller.dart';
import 'controllers/activity_controller.dart';
import 'outdoor_result_page.dart';

class OutdoorTrackingPage extends StatefulWidget {
  const OutdoorTrackingPage({super.key, required this.activityType});

  final String activityType;

  @override
  State<OutdoorTrackingPage> createState() => _OutdoorTrackingPageState();
}

class _OutdoorTrackingPageState extends State<OutdoorTrackingPage>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isStopping = false;

  // Panel height states
  final double _panelMinHeight = 240;
  final double _panelMaxHeight = 420;
  double _panelHeight = 240;
  bool _panelExpanded = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Pause ripple animation
  late AnimationController _pauseController;
  late Animation<double> _pauseAnim;

  @override
  void initState() {
    super.initState();

    // Pulse marker saat aktif
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Pause badge animation
    _pauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pauseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pauseController, curve: Curves.easeInOut),
    );

    _startTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pauseController.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    final controller = context.read<ActivityController>();
    controller.setActivityType(widget.activityType);
    final success = await controller.startTracking();
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS belum aktif atau izin lokasi ditolak'),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _togglePause() {
    final ctrl = context.read<ActivityController>();
    if (ctrl.isPaused) {
      ctrl.resumeTracking();
    } else {
      ctrl.pauseTracking();
    }
  }

  Future<void> _stopTracking() async {
    if (_isStopping) return;

    // Pastikan resume dulu jika sedang pause sebelum stop
    final ctrl = context.read<ActivityController>();
    if (ctrl.isPaused) {
      // tidak perlu resume, langsung stop
    }

    setState(() => _isStopping = true);

    final authController = context.read<AuthController>();
    final activityController = context.read<ActivityController>();

    if (authController.userEmail == null) {
      setState(() => _isStopping = false);
      return;
    }

    await activityController.stopTracking(authController.userEmail!);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OutdoorResultPage()),
    );
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'Running':
        return Icons.directions_run;
      case 'Cycling':
        return Icons.directions_bike;
      default:
        return Icons.directions_walk;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'Running':
        return const Color(0xFFE91E63);
      case 'Cycling':
        return const Color(0xFF2196F3);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityController = context.watch<ActivityController>();
    final routePoints = activityController.routeLatLngs;
    final currentPos = routePoints.isNotEmpty ? routePoints.last : null;
    final isPaused = activityController.isPaused;
    final actColor = _activityColor(widget.activityType);

    return Scaffold(
      body: Stack(
        children: [
          // ── MAP ─────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPos ?? const LatLng(-6.2088, 106.8456),
              initialZoom: 16,
              onPositionChanged: (_, __) {},
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fitrack.app',
              ),
              if (routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: isPaused
                          ? actColor.withOpacity(0.4)
                          : actColor,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),
              if (currentPos != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPos,
                      width: 56,
                      height: 56,
                      child: isPaused
                          // Saat pause: ikon pause statis beranimasi fade
                          ? AnimatedBuilder(
                              animation: _pauseAnim,
                              builder: (_, __) => Opacity(
                                opacity: _pauseAnim.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.orange.withOpacity(0.25),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.pause_circle_filled,
                                      color: Colors.orange,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          // Saat aktif: pulse marker
                          : AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) => Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: actColor.withOpacity(
                                    0.25 * _pulseAnim.value,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: actColor,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: actColor.withOpacity(0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
            ],
          ),

          // ── PAUSE OVERLAY ───────────────────────────────────────────────────
          if (isPaused)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isPaused ? 1 : 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.08),
                  ),
                ),
              ),
            ),

          // ── TOP BAR ─────────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Back
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Activity badge + status
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isPaused ? Colors.orange : actColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: (isPaused ? Colors.orange : actColor)
                              .withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaused
                              ? Icons.pause_rounded
                              : _activityIcon(widget.activityType),
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPaused ? 'Dijeda' : widget.activityType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedBuilder(
                          animation: isPaused
                              ? _pauseAnim
                              : const AlwaysStoppedAnimation(1.0),
                          builder: (_, __) => Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPaused
                                  ? Colors.white.withOpacity(_pauseAnim.value)
                                  : Colors.greenAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Re-center button
                  if (currentPos != null)
                    GestureDetector(
                      onTap: () => _mapController.move(currentPos, 16),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── BOTTOM SLIDING PANEL ────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _panelHeight -= details.delta.dy;
                  _panelHeight = _panelHeight.clamp(
                    _panelMinHeight,
                    _panelMaxHeight,
                  );
                  _panelExpanded = _panelHeight > _panelMinHeight + 60;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: _panelHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 24,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    // ── PAUSE BANNER ───────────────────────────────────────
                    if (isPaused)
                      AnimatedBuilder(
                        animation: _pauseAnim,
                        builder: (_, __) => Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pause_circle_outline_rounded,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Aktivitas sedang dijeda — Istirahatlah sejenak',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Stats Grid
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _statCard(
                                    icon: Icons.straighten_rounded,
                                    label: 'Jarak',
                                    value: activityController.distanceKm
                                        .toStringAsFixed(2),
                                    unit: 'km',
                                    color: actColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _statCard(
                                    icon: Icons.timer_outlined,
                                    label: 'Moving Time',
                                    value: _formatDuration(
                                      activityController.durationSeconds,
                                    ),
                                    unit: '',
                                    color: const Color(0xFF2196F3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _statCard(
                                    icon: Icons.terrain_rounded,
                                    label: 'Elevation',
                                    value: activityController.elevationGainM
                                        .toStringAsFixed(0),
                                    unit: 'm',
                                    color: const Color(0xFF4CAF50),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _statCard(
                                    icon: Icons.speed_rounded,
                                    label: 'Pace',
                                    value: activityController.formattedPace,
                                    unit: '/km',
                                    color: const Color(0xFFFF9800),
                                  ),
                                ),
                              ],
                            ),
                            if (_panelExpanded) ...[
                              const SizedBox(height: 10),
                              _statCard(
                                icon: Icons.local_fire_department_rounded,
                                label: 'Kalori',
                                value: activityController.caloriesBurned
                                    .toStringAsFixed(0),
                                unit: 'kcal',
                                color: const Color(0xFFE91E63),
                                fullWidth: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // ── ACTION BUTTONS area ───────────────────────────────
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Row(
                        children: [
                          // PAUSE / RESUME Button
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: _togglePause,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPaused
                                      ? const Color(0xFF4CAF50)
                                      : Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 0,
                                ),
                                icon: Icon(
                                  isPaused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  size: 22,
                                ),
                                label: Text(
                                  isPaused ? 'Lanjut' : 'Jeda',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // STOP Button
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: _isStopping ? null : _stopTracking,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF5350),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 0,
                                ),
                                icon: _isStopping
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.stop_circle_rounded,
                                        size: 24,
                                      ),
                                label: Text(
                                  _isStopping ? 'Menyimpan...' : 'Stop',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: fullWidth
          ? Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$value $unit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      if (unit.isNotEmpty)
                        TextSpan(
                          text: ' $unit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: color.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
