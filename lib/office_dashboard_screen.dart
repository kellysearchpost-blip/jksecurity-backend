import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io_client;

class OfficeDashboardScreen extends StatefulWidget {
  const OfficeDashboardScreen({super.key});

  @override
  State<OfficeDashboardScreen> createState() => _OfficeDashboardScreenState();
}

class _OfficeDashboardScreenState extends State<OfficeDashboardScreen> {
  int _selectedNavIndex = 0;
  List<dynamic> _reports = [];
  bool _isLoading = true;
  late io_client.Socket socket;

  static const primaryBlue = Color(0xFF0D47A1);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initWebSocket();
  }

  void _initWebSocket() {
    socket = io_client.io(
      'http://localhost:3000',
      io_client.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('=== WEBSOCKET CONNECTED ===');
    });

    socket.onConnectError((data) => debugPrint('Connect Error: $data'));
    socket.onError((data) => debugPrint('Socket Error: $data'));

    socket.on('new_report', (data) {
      if (mounted) {
        setState(() {
          _reports.insert(0, Map<String, dynamic>.from(data));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New Live Report Received from ${data['supervisor']}!'),
            backgroundColor: Colors.blue.shade800,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  Future<void> _loadDashboardData() async {
    final fetchedData = await ApiService.fetchReports();
    if (mounted) {
      setState(() {
        _reports = fetchedData;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  // Helper method to safely convert string coordinates to LatLng
  LatLng _parseCoordinates(String? coordString) {
    if (coordString == null || !coordString.contains(',')) {
      return const LatLng(-1.286389, 36.817223); // Default Nairobi center
    }
    final parts = coordString.split(',');
    final lat = double.tryParse(parts[0].trim()) ?? -1.286389;
    final lng = double.tryParse(parts[1].trim()) ?? 36.817223;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Row(
        children: [
          // --- LEFT SIDEBAR NAVIGATION ---
          NavigationRail(
            backgroundColor: primaryBlue,
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedNavIndex = index);
            },
            extended: MediaQuery.of(context).size.width > 900,
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            selectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Colors.white, size: 32),
                  if (MediaQuery.of(context).size.width > 900) ...[
                    const SizedBox(width: 10),
                    const Text(
                      'SecurePro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.location_city_outlined),
                selectedIcon: Icon(Icons.location_city),
                label: Text('Sites'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.badge_outlined),
                selectedIcon: Icon(Icons.badge),
                label: Text('Supervisors'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.warning_amber_outlined),
                selectedIcon: Icon(Icons.warning_amber),
                label: Text('Incidents'),
              ),
            ],
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // --- MAIN CONTENT AREA ---
          Expanded(
            child: Column(
              children: [
                // TOP HEADER BAR
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Office Operations Dashboard',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Badge(
                              label: Text('3'),
                              child: Icon(Icons.notifications_outlined),
                            ),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 16),
                          const CircleAvatar(
                            backgroundColor: primaryBlue,
                            child: Text('AD', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          const Text('Owner / Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                // DASHBOARD BODY
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // METRICS ROW
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double cardWidth = (constraints.maxWidth - 48) / 4;
                            if (constraints.maxWidth < 800) cardWidth = (constraints.maxWidth - 16) / 2;

                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _buildMetricCard('Total Sites', '12', Icons.location_on, Colors.blue, cardWidth),
                                _buildMetricCard('Active Supervisors', '8', Icons.person_pin, Colors.green, cardWidth),
                                _buildMetricCard('Guards On Duty', '48', Icons.security, Colors.orange, cardWidth),
                                _buildMetricCard('Reports Today', '${_reports.length}', Icons.fact_check, Colors.purple, cardWidth),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // MIDDLE SECTION: LIVE FEED & MAP
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LIVE ACTIVITY FEED
                            Expanded(
                              flex: 3,
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Live Supervisor Feed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.refresh, size: 20),
                                            onPressed: _loadDashboardData,
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      _buildFeedTile('Supervisor John Kamau', 'Arrived at City Mall', '08:45 AM', Icons.location_on, Colors.green),
                                      _buildFeedTile('Supervisor Peter Odhiambo', 'Submitted Report for Green Park', '08:15 AM', Icons.assignment_turned_in, Colors.blue),
                                      _buildFeedTile('Supervisor Daniel Maina', 'Incident Logged at Tech Warehouse', '07:30 AM', Icons.warning, Colors.red),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // SITES MAP OVERVIEW
                            Expanded(
                              flex: 2,
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: Container(
                                  height: 280,
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Sites Location Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: FlutterMap(
                                            options: MapOptions(
                                              initialCenter: _reports.isNotEmpty && _reports.first['coordinates'] != null
                                                  ? _parseCoordinates(_reports.first['coordinates'])
                                                  : const LatLng(-1.286389, 36.817223),
                                              initialZoom: 12.0,
                                            ),
                                            children: [
                                              TileLayer(
                                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                userAgentPackageName: 'com.jksecurity.app',
                                              ),
                                              MarkerLayer(
                                                markers: _reports.map((report) {
                                                  final pos = _parseCoordinates(report['coordinates']);
                                                  final isIncident = report['type'] == 'Emergency Check' || report['type'] == 'Incident';

                                                  return Marker(
                                                    point: pos,
                                                    width: 40,
                                                    height: 40,
                                                    child: GestureDetector(
                                                      onTap: () => _showReportDetailsDialog(Map<String, dynamic>.from(report)),
                                                      child: Tooltip(
                                                        message: '${report['siteName']} (${report['supervisor']})',
                                                        child: Icon(
                                                          Icons.location_on,
                                                          color: isIncident ? Colors.red : Colors.blue,
                                                          size: 36,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // RECENT INSPECTION REPORTS TABLE (DYNAMIC API DATA)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Recent Supervisor Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                _isLoading
                                    ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                                    : SizedBox(
                                        width: double.infinity,
                                        child: DataTable(
                                          columns: const [
                                            DataColumn(label: Text('Site Name')),
                                            DataColumn(label: Text('Supervisor')),
                                            DataColumn(label: Text('Time')),
                                            DataColumn(label: Text('Type')),
                                            DataColumn(label: Text('Status')),
                                            DataColumn(label: Text('Photo')),
                                            DataColumn(label: Text('Action')),
                                          ],
                                          rows: _reports.map((report) {
                                            return _buildReportRow(
                                              report['siteName'] ?? 'N/A',
                                              report['supervisor'] ?? 'N/A',
                                              report['time'] ?? 'N/A',
                                              report['type'] ?? 'Routine Check',
                                              report['status'] ?? 'Completed',
                                              report['status'] == 'Completed' ? Colors.green : Colors.red,
                                              Map<String, dynamic>.from(report),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- REPORT DETAILS MODAL DIALOG ---
void _showReportDetailsDialog(Map<String, dynamic> report) {
  final photoUrl = report['photoUrl'];
  final fullImageUrl = (photoUrl != null && photoUrl.toString().startsWith('/'))
      ? 'http://localhost:3000$photoUrl'
      : photoUrl;

  final updatedReport = Map<String, dynamic>.from(report)..['photoUrl'] = fullImageUrl;

  showDialog(
    context: context,
    builder: (context) => ReportDetailsDialog(report: updatedReport),
  );
}

  Widget _buildMetricCard(String title, String count, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedTile(String title, String subtitle, String time, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
    );
  }

  DataRow _buildReportRow(
  String siteName,
  String supervisor,
  String time,
  String type,
  String status,
  Color statusColor,
  Map<String, dynamic> reportData,
) {
  final photoUrl = reportData['photoUrl'];

  return DataRow(
    cells: [
      DataCell(Text(siteName, style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(supervisor)),
      DataCell(Text(time)),
      DataCell(Text(type)),
      DataCell(
        Chip(
          label: Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
          backgroundColor: statusColor.withValues(alpha: 0.1),
          side: BorderSide.none,
        ),
      ),
      // --- PHOTO THUMBNAIL DATACELL ---
      DataCell(
        photoUrl != null && photoUrl.toString().isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  photoUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 22, color: Colors.grey),
                ),
              )
            : const Icon(Icons.no_photography_outlined, color: Colors.grey, size: 22),
      ),
      // --- ACTION BUTTON ---
      DataCell(
        OutlinedButton(
          onPressed: () => _showReportDetailsDialog(reportData),
          child: const Text('View Details', style: TextStyle(fontSize: 12)),
        ),
      ),
    ],
  );
}
}

class ReportDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportDetailsDialog({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final photoUrl = report['photoUrl'];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('${report['siteName']} - Report Details'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Submitter Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade100, // Fixed getter error & constant error
                    child: const Icon(Icons.person, color: Colors.deepPurple),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['guardName'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Submitted at ${report['time']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),

              // Evidence Photo Section
              const Text('Evidence Photo:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              photoUrl != null && photoUrl.toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photoUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('Failed to load image evidence.'),
                      ),
                    )
                  : Text(
                      'No photo attached.',
                      style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                    ),
              const SizedBox(height: 16),

              // Supervisor Notes
              const Text('Supervisor Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(report['notes'] ?? 'No extra notes provided.'),
              const SizedBox(height: 16),

              // Location Coordinates
              const Text('Location Coordinates:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                '${report['coordinates'] ?? 'N/A'} (GPS Verified)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}