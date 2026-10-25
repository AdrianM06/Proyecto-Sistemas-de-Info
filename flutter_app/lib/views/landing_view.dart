import 'package:flutter/material.dart';
import 'registration_screen.dart';

class LandingView extends StatelessWidget {
  const LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    const Color unimetBlue = Color(0xFF003087);
    const Color unimetOrange = Color(0xFFFF8200);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth >= 800;

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. Barra de Navegación Superior
                _buildNavBar(context, unimetBlue, unimetOrange),

                // 2. Sección Principal (Hero Banner)
                _buildHeroSection(context, isDesktop, unimetBlue, unimetOrange),

                // 3. Sección de Características (Llamado a la Parte 2)
                const LandingFeaturesSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, Color unimetBlue, Color unimetOrange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: unimetBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'UNIMET',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Samán Deportivo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: unimetBlue,
                ),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: unimetOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegistrationScreen()),
              );
            },
            child: const Text('Acceder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDesktop, Color unimetBlue, Color unimetOrange) {
    return Container(
      width: double.infinity,
      height: isDesktop ? 500 : 350,
      decoration: BoxDecoration(
        color: unimetBlue,
        gradient: LinearGradient(
          colors: [unimetBlue, unimetBlue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Bienvenido a Samán Deportivo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gestiona tus disciplinas, entrenamientos y reservas de forma rápida y eficiente en la Universidad Metropolitana.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: unimetOrange,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                );
              },
              child: const Text(
                'Comenzar Ahora',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandingFeaturesSection extends StatelessWidget {
  const LandingFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    const Color unimetBlue = Color(0xFF003087);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Text(
            'Nuestros Módulos Principales',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: unimetBlue),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureCard(Icons.sports_soccer, 'Gestión Deportiva', 'Control de disciplinas y torneos activos.'),
              _buildFeatureCard(Icons.person, 'Perfil de Usuario', 'Administra tus datos y rol institucional.'),
              _buildFeatureCard(Icons.calendar_today, 'Entrenamientos', 'Sigue de cerca las rutinas con los entrenadores.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFF003087)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}
