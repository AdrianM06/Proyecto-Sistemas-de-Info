// /lib/views/profile_view.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileView extends StatefulWidget {
  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color unimetBlue = Color(0xFF003087);
    const Color unimetOrange = Color(0xFFFF8200);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Perfil de Usuario', style: TextStyle(color: Colors.white)),
        backgroundColor: unimetBlue,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: unimetOrange))
          : _userData == null
              ? Center(child: Text('No se pudo obtener la información del usuario.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      Center(
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: unimetOrange,
                          child: Text(
                            (_userData!['nombre'] != null && _userData!['nombre'].toString().isNotEmpty)
                                ? _userData!['nombre'][0].toString().toUpperCase()
                                : 'U',
                            style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        '${_userData!['nombre'] ?? ''} ${_userData!['apellido'] ?? ''}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: unimetBlue),
                      ),
                      Text(
                        _userData!['email'] ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 25),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.badge, color: unimetBlue),
                                title: Text('Carnet Institucional'),
                                subtitle: Text(_userData!['carnet'] ?? 'No registrado'),
                              ),
                              Divider(height: 1),
                              ListTile(
                                leading: Icon(Icons.school, color: unimetBlue),
                                title: Text('Carrera / Programa'),
                                subtitle: Text(_userData!['carrera'] ?? 'No registrada'),
                              ),
                              Divider(height: 1),
                              ListTile(
                                leading: Icon(Icons.admin_panel_settings, color: unimetBlue),
                                title: Text('Rol Asignado'),
                                subtitle: Text((_userData!['rol'] ?? 'estudiante').toString().toUpperCase()),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: Icon(Icons.logout, color: Colors.white),
                          label: Text('Cerrar Sesión', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            await _auth.signOut();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
