import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/deporte.dart';
import '../../services/firestore_service.dart';

const _azul = Color(0xFF003B82);

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard - Deportes y Horarios'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.instance.sports.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay deportes registrados.'));
          }

          final deportes = snapshot.data!.docs
              .map((doc) => Deporte.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deportes.length,
            itemBuilder: (context, index) {
              final deporte = deportes[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            deporte.nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Chip(
                            label: Text('${deporte.cupos} Cupos'),
                            backgroundColor: Colors.blue.shade50,
                          ),
                        ],
                      ),
                      if (deporte.disciplina.isNotEmpty)
                        Text(
                          deporte.disciplina,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: _azul, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Horarios: ${deporte.horariosTexto}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (deporte.lugar.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined,
                                color: Colors.grey, size: 18),
                            const SizedBox(width: 8),
                            Text(deporte.lugar),
                          ],
                        ),
                      ],
                      if (deporte.etiquetas.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: deporte.etiquetas.map((e) {
                            return Chip(
                              label: Text('#$e',
                                  style: const TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.orange.shade50,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}