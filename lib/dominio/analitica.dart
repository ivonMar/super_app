import 'dinero.dart';
import 'eventos.dart';

class RegistroUso {
  final String usuarioId;
  final Servicio servicio;
  final DateTime fecha;
  const RegistroUso(this.usuarioId, this.servicio, this.fecha);
}

class Analitica {
  final List<RegistroUso> registros = [];

  void conectar(BusEventos bus) {
    bus.suscribir<EventoApp>((e) {
      if (e.cuentaComoUso) registros.add(RegistroUso(e.usuarioId, e.servicio, e.fecha));
    });
  }

  void agregar(RegistroUso r) => registros.add(r);

  Set<String> _activosEntre(DateTime desde, DateTime hasta) => {
        for (final r in registros)
          if (!soloFecha(r.fecha).isBefore(soloFecha(desde)) && !soloFecha(r.fecha).isAfter(soloFecha(hasta)))
            r.usuarioId,
      };

  int dau(DateTime dia) => _activosEntre(dia, dia).length;
  int wau(DateTime dia) => _activosEntre(masDias(dia, -6), dia).length;
  int mau(DateTime dia) => _activosEntre(masDias(dia, -29), dia).length;

  double stickiness(DateTime dia) {
    final m = mau(dia);
    return m == 0 ? 0 : dau(dia) / m;
  }

  DateTime? primerDia(String usuario) {
    DateTime? menor;
    for (final r in registros) {
      if (r.usuarioId != usuario) continue;
      final d = soloFecha(r.fecha);
      if (menor == null || d.isBefore(menor)) menor = d;
    }
    return menor;
  }

  Set<String> cohorte(DateTime dia) {
    final d = soloFecha(dia);
    return {for (final u in registros.map((r) => r.usuarioId).toSet()) if (primerDia(u) == d) u};
  }

  double retencion(DateTime dia, int n) {
    final c = cohorte(dia);
    if (c.isEmpty) return 0;
    final objetivo = masDias(soloFecha(dia), n);
    final volvieron = _activosEntre(objetivo, objetivo).where(c.contains).length;
    return volvieron / c.length;
  }

  double serviciosPorUsuario(DateTime desde, DateTime hasta) {
    final por = _serviciosPorUsuario(desde, hasta);
    if (por.isEmpty) return 0;
    return por.values.fold<int>(0, (s, v) => s + v.length) / por.length;
  }

  double porcentajeMultiservicio(DateTime desde, DateTime hasta, {int minimo = 2}) {
    final por = _serviciosPorUsuario(desde, hasta);
    if (por.isEmpty) return 0;
    return por.values.where((s) => s.length >= minimo).length / por.length;
  }

  Map<String, Set<Servicio>> _serviciosPorUsuario(DateTime desde, DateTime hasta) {
    final por = <String, Set<Servicio>>{};
    for (final r in registros) {
      final d = soloFecha(r.fecha);
      if (d.isBefore(soloFecha(desde)) || d.isAfter(soloFecha(hasta))) continue;
      (por[r.usuarioId] ??= {}).add(r.servicio);
    }
    return por;
  }

  ({double unServicio, double multiservicio, int nUno, int nMulti}) retencionSemana2PorServicios(
      DateTime desde, DateTime hasta) {
    var nUno = 0, nMulti = 0, retUno = 0, retMulti = 0;
    for (final u in registros.map((r) => r.usuarioId).toSet()) {
      final p = primerDia(u)!;
      if (p.isBefore(soloFecha(desde)) || p.isAfter(soloFecha(hasta))) continue;
      final semana1 = <Servicio>{};
      var retenido = false;
      for (final r in registros) {
        if (r.usuarioId != u) continue;
        final f = soloFecha(r.fecha);
        final k = _diasEntre(p, f);
        if (k >= 0 && k <= 6) semana1.add(r.servicio);
        if (k >= 7 && k <= 13) retenido = true;
      }
      if (semana1.length >= 2) {
        nMulti++;
        if (retenido) retMulti++;
      } else {
        nUno++;
        if (retenido) retUno++;
      }
    }
    return (
      unServicio: nUno == 0 ? 0 : retUno / nUno,
      multiservicio: nMulti == 0 ? 0 : retMulti / nMulti,
      nUno: nUno,
      nMulti: nMulti,
    );
  }

  static int _diasEntre(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}