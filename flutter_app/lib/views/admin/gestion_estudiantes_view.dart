import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/firestore_service.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFFF8C2A);

class GestionEstudiantesView extends StatelessWidget {
  const GestionEstudiantesView({super.key});

  Future<void> _cambiarEstado(String uid, bool nuevoEstado) async {
    await FirestoreService.instance.users.doc(uid).update({
      'estadoActivo': nuevoEstado,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Estudiantes'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.instance.users
            .where('rol', isEqualTo: 'estudiante')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay estudiantes registrados.'));
          }

          final estudiantes = snapshot.data!.docs
              .map((doc) => Usuario.fromFirestore(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: estudiantes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final estudiante = estudiantes[index];

              return Card(
                elevation: 1,
                child: SwitchListTile(
                  activeColor: _naranja,
                  title: Text(
                    estudiante.nombreCompleto,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Carnet: ${estudiante.carnet ?? "S/C"} | Cédula: ${estudiante.cedula ?? "S/C"}',
                  ),
                  value: estudiante.estadoActivo,
                  secondary: CircleAvatar(
                    backgroundColor: estudiante.estadoActivo
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    child: Icon(
                      estudiante.estadoActivo ? Icons.check_circle : Icons.block,
                      color: estudiante.estadoActivo ? Colors.green : Colors.red,
                    ),
                  ),
                  onChanged: (val) => _cambiarEstado(estudiante.uid, val),
                ),
              );
            },
          );
        },
      ),
    );
  }
}