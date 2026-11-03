# Samán Deportivo (app Flutter)

Plataforma de deportes de la Universidad Metropolitana: Flutter (web) +
Firebase (Authentication, Cloud Firestore y Storage).

## Correr la app

```bash
cd flutter_app
flutter pub get
flutter run -d chrome
```

## Pruebas locales (antes de cada commit)

Las pruebas usan `flutter_test`, que ya viene con Flutter. Corre esto en
tu computadora antes de subir cambios, en lugar de hacer "commits de
prueba":

```bash
cd flutter_app
flutter pub get
flutter analyze          # revisa errores del código
flutter test             # corre todas las pruebas
```

Para correr solo un grupo de pruebas:

```bash
flutter test test/utils/app_validators_test.dart   # validaciones del registro y login
flutter test test/views/registro_test.dart          # formulario de registro
flutter test test/widget_test.dart                  # Landing, login y navegación
```

GitHub corre las mismas pruebas en cada Pull Request (`.github/workflows/flutter-ci.yml`).

## Reglas de Firebase

Las reglas viven en la raíz del repositorio:

- `firestore.rules`: permisos por rol y validación de los datos del registro.
- `storage.rules`: fotos de perfil (`usuarios/{uid}/...`, solo imágenes de hasta 2 MB).

Se publican con la CLI de Firebase (o copiándolas en la consola):

```bash
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules,storage
```

## Primer administrador

Las cuentas admin no se crean desde la app. En la consola de Firebase, en
Firestore, abre `users/{uid}` de la cuenta y cambia `rol` a `"admin"`.
Desde el panel admin se registran los entrenadores.
