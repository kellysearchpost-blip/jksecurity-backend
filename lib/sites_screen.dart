import 'package:flutter/material.dart';

class SitesScreen extends StatelessWidget {
  const SitesScreen({super.key});

  final List<Map<String, dynamic>> sites = const [
    {
      'name': 'City Mall — Main Complex',
      'address': '123 City Street, Nairobi',
      'coordinates': '-1.286389, 36.817223',
      'contactName': 'Peter Njoroge (Chief Security)',
      'contactPhone': '+254 700 000 111',
      'status': 'Assigned Post',
      'postOrders': [
        'Perform perimeter patrol every 2 hours.',
        'Ensure main entrance visitor log is signed.',
        'Verify emergency exits remain unblocked.',
      ],
    },
    {
      'name': 'Westside Logistics Hub',
      'address': 'Industrial Area, Gate 4',
      'coordinates': '-1.300000, 36.850000',
      'contactName': 'Mary Wanjiku (Site Manager)',
      'contactPhone': '+254 700 000 222',
      'status': 'Secondary Site',
      'postOrders': [
        'Check cargo truck seal numbers on entry.',
        'Inspect guard shack logbook at shift handover.',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Security Sites', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sites.length,
        itemBuilder: (context, index) {
          final site = sites[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          site['name'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: index == 0 ? Colors.blue.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          site['status'],
                          style: TextStyle(
                            color: index == 0 ? const Color(0xFF0D47A1) : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(site['address'], style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.gps_fixed, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text('GPS: ${site['coordinates']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Post Orders & Guidelines:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D47A1)),
                  ),
                  const SizedBox(height: 8),
                  ...List<Widget>.from(
                    site['postOrders'].map((order) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(order, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        )),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(site['contactName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(site['contactPhone'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone, color: Color(0xFF0D47A1)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling ${site['contactName']}...')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}