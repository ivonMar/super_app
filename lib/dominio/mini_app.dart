import 'excepciones.dart';

enum Permiso {
  identidad,
  monederoLeer,
  monederoPagar,
  mensajesLeer,
  mensajesEscribir,
  ubicacion,
}

class MiniApp {
  final String id;
  final String nombre;
  final String emoji;
  final Set<Permiso> permisos;
  const MiniApp(this.id, this.nombre, this.emoji, this.permisos);
}

class RegistroMiniApps {
  final Map<String, MiniApp> _apps = {};
  final Set<String> _apagadas = {};

  void registrar(MiniApp app) {
    if (_apps.containsKey(app.id)) throw ArgumentError('Ya existe la mini-app ${app.id}');
    _apps[app.id] = app;
  }

  MiniApp? porId(String id) => _apps[id];

  List<MiniApp> get activas => _apps.values.where((a) => !_apagadas.contains(a.id)).toList();

  bool estaActiva(String id) => _apps.containsKey(id) && !_apagadas.contains(id);

  void apagar(String id) => _apagadas.add(id);
  void encender(String id) => _apagadas.remove(id);

  void exigeActiva(String id) {
    if (!estaActiva(id)) throw const MiniAppNoDisponibleException();
  }
}