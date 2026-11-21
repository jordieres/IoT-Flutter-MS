import 'package:flutter/material.dart';

import 'Api/SensoriaApi.dart';
import 'sensoria_setup_screen.dart';

const _navy = Color(0xff153865);
const _surface = Color(0xfff2f6fc);
const _border = Color(0xffd5e2f3);

class HealthyWearSettingsScreen extends StatelessWidget {
  const HealthyWearSettingsScreen({super.key, required this.locale});

  final Locale locale;

  String _tr(String english, String spanish) =>
      locale.languageCode == 'es' ? spanish : english;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => _page(
        title: _tr('Settings', 'Ajustes'),
        children: [
          Text(_tr('Devices', 'Dispositivos'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _navy,
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 14),
          Material(
            color: _navy,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _open(context, _socksPage(context)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xff235080),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const SensoriaSockIllustration(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_tr('Sensoria socks', 'Calcetines Sensoria'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              )),
                          const SizedBox(height: 4),
                          Text(
                              _tr('Sensor settings and calibration',
                                  'Ajustes de sensores y calibración'),
                              style: const TextStyle(
                                color: Color(0xffdfebfa),
                                fontSize: 15,
                              )),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  String _foot(int slot) => slot == 2
      ? _tr('Left sock', 'Calcetín izquierdo')
      : _tr('Right sock', 'Calcetín derecho');

  Widget _socksPage(BuildContext context) =>
      ValueListenableBuilder<Map<int, Map<String, int>>>(
        valueListenable: SensoriaApi.connectedSettings,
        builder: (context, connected, _) => _page(
          title: _tr('Sensoria socks', 'Calcetines Sensoria'),
          children: [
            for (final slot in [2, 1]) ...[
              _card(ListTile(
                enabled: connected.containsKey(slot),
                leading: Icon(
                  connected.containsKey(slot)
                      ? Icons.sensors
                      : Icons.sensors_off,
                ),
                title: Text(_foot(slot)),
                subtitle: Text(connected.containsKey(slot)
                    ? _tr('Connected', 'Conectado')
                    : _tr('Not connected', 'Sin conexión')),
                trailing: connected.containsKey(slot)
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: connected.containsKey(slot)
                    ? () => _open(context, _sockPage(slot))
                    : null,
              )),
              const SizedBox(height: 12),
            ],
          ],
        ),
      );

  Widget _sockPage(int slot) =>
      ValueListenableBuilder<Map<int, Map<String, int>>>(
        valueListenable: SensoriaApi.connectedSettings,
        builder: (context, connected, _) {
          final values = connected[slot];
          return _page(
            title: _foot(slot),
            children: [
              if (values == null)
                Text(_tr('Reconnect this sock to see its settings.',
                    'Vuelve a conectar este calcetín para ver sus ajustes.'))
              else ...[
                _sensorCard(
                    _tr('Accelerometer', 'Acelerómetro'),
                    Icons.speed_outlined,
                    values['accelerometerG'],
                    'g',
                    values['accelerometerHz']),
                _sensorCard(_tr('Gyroscope', 'Giroscopio'), Icons.rotate_right,
                    values['gyroscopeDps'], '°/s', values['gyroscopeHz']),
                _sensorCard(
                    _tr('Magnetometer', 'Magnetómetro'),
                    Icons.explore_outlined,
                    values['magnetometerGauss'],
                    'G',
                    values['magnetometerHz']),
                const SizedBox(height: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: _navy,
                  ),
                  onPressed: SensoriaApi.isRecording
                      ? null
                      : () => _open(
                          context,
                          SensoriaSetupScreen(
                            locale: locale,
                            connectedSlots: () => SensoriaApi
                                .connectedSettings.value.keys
                                .toSet(),
                            calibrationSlot: slot,
                          )),
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(
                      _tr('Calibrate this sock', 'Calibrar este calcetín')),
                ),
                if (SensoriaApi.isRecording)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_tr('Stop recording before calibrating.',
                        'Detén la grabación antes de calibrar.')),
                  ),
              ],
            ],
          );
        },
      );

  Widget _sensorCard(
      String title, IconData icon, int? range, String unit, int? rate) {
    final unavailable = _tr('Unavailable', 'No disponible');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: _navy),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ))),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 28,
              runSpacing: 8,
              children: [
                _reading(_tr('Range', 'Rango'),
                    range == null ? unavailable : '±$range $unit'),
                _reading(_tr('Sampling rate', 'Frecuencia de muestreo'),
                    rate == null ? unavailable : '$rate Hz'),
              ],
            ),
          ],
        ),
      )),
    );
  }

  Widget _reading(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xff455c76))),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                color: _navy,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              )),
        ],
      );

  Widget _card(Widget child) => Material(
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: _border),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: child,
      );

  Widget _page({required String title, required List<Widget> children}) =>
      Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(title: Text(title), backgroundColor: _surface),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                children: children,
              ),
            ),
          ),
        ),
      );
}
