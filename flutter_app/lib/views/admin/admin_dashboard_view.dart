import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/deporte.dart';
import '../../services/firestore_service.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFF58220);

/// Panel del administrador: accesos rápidos (registrar entrenadores, crear
/// disciplinas, gestionar estudiantes) y la lista de deportes con sus
/// horarios y etiquetas.
class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({
    super.key,
    this.nombreAdmin = 'Administrador',
    this.avatar,
    this.onAbrirPerfil,
    this.onCerrarSesion,
    this.onIrALanding,
    this.onRegistrarEntrenador,
    this.onCrearDeporte,
    this.onGestionarEstudiantes,
    this.onGestionarEntrenadores,
  });

  final String nombreAdmin;

  /// Foto de perfil de la barra superior. Si es `null` se ve un ícono.
  final Widget? avatar;

  /// Abre el perfil del administrador (solo foto; sin cambio de contraseña).
  final VoidCallback? onAbrirPerfil;
  final VoidCallback? onCerrarSesion;

  /// Botón "Página principal": vuelve a la Landing sin cerrar la sesión.
  final VoidCallback? onIrALanding;
  final VoidCallback? onRegistrarEntrenador;
  final VoidCallback? onCrearDeporte;
  final VoidCallback? onGestionarEstudiantes;

  /// Abre la lista de entrenadores para asignar o revocar disciplinas.
  final VoidCallback? onGestionarEntrenadores;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administración'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        actions: [
          if (onAbrirPerfil != null)
            IconButton(
              key: const Key('boton-perfil'),
              tooltip: 'Mi perfil',
              onPressed: onAbrirPerfil,
              icon: avatar ?? const Icon(Icons.account_circle),
            ),
          if (onIrALanding != null)
            IconButton(
              key: const Key('boton-ir-landing'),
              tooltip: 'Página principal',
              onPressed: onIrALanding,
              icon: const Icon(Icons.home_outlined),
            ),
          if (onCerrarSesion != null)
            IconButton(
              key: const Key('boton-cerrar-sesion'),
              tooltip: 'Cerrar sesión',
              onPressed: onCerrarSesion,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text(
              'Hola, $nombreAdmin',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _azul,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AccionAdmin(
                  key: const Key('admin-registrar-entrenador'),
                  icono: Icons.person_add_alt_1,
                  titulo: 'Registrar entrenador',
                  onTap: onRegistrarEntrenador,
                ),
                _AccionAdmin(
                  key: const Key('admin-gestionar-entrenadores'),
                  icono: Icons.manage_accounts_outlined,
                  titulo: 'Gestionar entrenadores',
                  onTap: onGestionarEntrenadores,
                ),
                _AccionAdmin(
                  key: const Key('admin-crear-deporte'),
                  icono: Icons.add_circle_outline,
                  titulo: 'Crear disciplina',
                  onTap: onCrearDeporte,
                ),
                _AccionAdmin(
                  key: const Key('admin-gestionar-estudiantes'),
                  icono: Icons.groups_outlined,
                  titulo: 'Gestionar estudiantes',
                  onTap: onGestionarEstudiantes,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Deportes y horarios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: _listaDeportes()),
        ],
      ),
    );
  }

  Widget _listaDeportes() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
    );
  }
}

class _AccionAdmin extends StatelessWidget {
  const _AccionAdmin({
    super.key,
    required this.icono,
    required this.titulo,
    this.onTap,
  });

  final IconData icono;
  final String titulo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icono, color: _naranja, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _azul,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
