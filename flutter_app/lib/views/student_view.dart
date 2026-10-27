import 'package:flutter/material.dart';

class StudentView extends StatelessWidget {
  const StudentView({super.key, this.onCerrarSesion, this.onAbrirPerfil});

  /// Botón "Cerrar sesión" de la barra superior (igual que en la vista del
  /// entrenador). Si es `null`, el botón no aparece.
  final VoidCallback? onCerrarSesion;

  /// Se llama al tocar la foto de perfil de la esquina superior derecha.
  final VoidCallback? onAbrirPerfil;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const Icon(Icons.menu, color: Colors.black),
        title: const Text('UNIMET SPORTS', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            key: const Key('avatar-perfil'),
            tooltip: 'Mi perfil',
            onPressed: onAbrirPerfil,
            icon: const Icon(Icons.person, color: Colors.grey, size: 30),
          ),
          if (onCerrarSesion != null)
            IconButton(
              key: const Key('boton-cerrar-sesion'),
              tooltip: 'Cerrar sesión',
              onPressed: onCerrarSesion,
              icon: const Icon(Icons.logout, color: Colors.black),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              children: [
                _buildSidebarButton('Inicio'),
                _buildSidebarButton('Catálogo'),
                _buildSidebarButton('Pagos'),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fecha de entrenamiento próximo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    color: Colors.white,
                    child: Container(
                      height: 250,
                      alignment: Alignment.center,
                      // Se recomienda usar el paquete table_calendar para el widget funcional
                      child: const Text('Calendario interactivo: Octubre 2026'), 
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('Disciplinas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.blue[900], size: 40),
                      title: const Text('Estás inscrito en', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text('Fútbol campo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarButton(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[900],
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () {},
        child: Text(title, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}