import 'package:flutter/material.dart';
import 'package:flutter_app/utils/app_validators.dart';

const _panelGray = Color(0xFFD9D9D9);
const _buttonBrown = Color(0xFF514943);
const _navy = Color(0xFF003B82);

class PasswordRecoveryScreen extends StatelessWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            return Container(
              color: _panelGray,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Stack(
                    children: [
                      const Positioned(top: 28, left: 28, child: _SportsLogo()),
                      const Center(child: _RecoveryContent()),
                    ],
                  ),
                ),
              ),
            );
          }

          return Container(
            color: _panelGray,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: _SportsLogo(),
                      ),
                      const SizedBox(height: 40),
                      const _RecoveryContent(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SportsLogo extends StatelessWidget {
  const _SportsLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/unimet_sports_logo.png',
          width: 184,
          height: 68,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _RecoveryContent extends StatefulWidget {
  const _RecoveryContent();

  @override
  State<_RecoveryContent> createState() => _RecoveryContentState();
}

class _RecoveryContentState extends State<_RecoveryContent> {
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Datos validados. El envío del código aún no está conectado.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'RECUPERAR CONTRASEÑA',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 25,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RecoveryField(
                    label: 'Correo Electrónico Unimet',
                    keyboardType: TextInputType.emailAddress,
                    validator: AppValidators.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  _RecoveryField(
                    label: 'Carnet Universitario',
                    keyboardType: TextInputType.number,
                    validator: AppValidators.validateCarnet,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonBrown,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Mandar Código',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                children: [
                  const TextSpan(
                    text: 'si ya tiene su contraseña, vuelva a la pagina de iniciar sesión ',
                  ),
                  TextSpan(
                    text: 'aqui',
                    style: const TextStyle(
                      color: _navy,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryField extends StatelessWidget {
  const _RecoveryField({
    required this.label,
    required this.keyboardType,
    required this.validator,
  });

  final String label;
  final TextInputType keyboardType;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black)),
        const SizedBox(height: 4),
        TextFormField(
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}