import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Api/SensoriaApi.dart';

class SensoriaSetupScreen extends StatefulWidget {
  const SensoriaSetupScreen({
    super.key,
    required this.locale,
    required this.connectedSlots,
    this.calibrationSlot,
  });

  final Locale locale;
  final int? calibrationSlot;
  final Set<int> Function() connectedSlots;

  @override
  State<SensoriaSetupScreen> createState() => _SensoriaSetupScreenState();
}

enum _TrialIssue { interrupted, disconnected, unavailable }

class _SensoriaSetupScreenState extends State<SensoriaSetupScreen>
    with WidgetsBindingObserver {
  static const _seconds = 20;
  static const _interval = Duration(milliseconds: 350);
  static const _navy = Color(0xff153865);
  static const _green = Color(0xff176b47);
  static const _red = Color(0xffa32937);

  final _trial = <int, _SockTrial>{};
  Timer? _refresh;
  Timer? _countdown;
  bool _reading = false;
  bool _closingCapture = false;
  bool _captureOpen = false;
  bool _finished = false;
  bool _guidance = false;
  int _remaining = _seconds;
  final _calibrationQueue = <int>[];
  bool _calibrating = false;
  bool _sockCalibrated = false;
  String? _calibrationError;
  _TrialIssue? _issue;

  String tr(String en, String es) =>
      widget.locale.languageCode == 'es' ? es : en;
  bool get _busy => _captureOpen || _closingCapture;
  Set<int> get _magneticIssues => {
        for (final entry in _trial.entries)
          if (entry.value.hasMagneticIssue ||
              SensoriaApi.calibrationStatus(entry.key) ==
                  SensoriaCalibrationStatus.suspect)
            entry.key,
      };

  @override
  void initState() {
    super.initState();
    if (widget.calibrationSlot case final int slot) {
      _calibrationQueue.add(slot);
      _guidance = true;
    }
    WidgetsBinding.instance.addObserver(this);
    _refresh = Timer.periodic(_interval, (_) => _update());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    _countdown?.cancel();
    if (_captureOpen) unawaited(_disableCapture());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _captureOpen) {
      unawaited(_stop(issue: _TrialIssue.interrupted));
    }
  }

  Future<void> _disableCapture() async {
    try {
      await SensoriaApi.setTrialCapture(false);
    } catch (_) {
      // The native buffer is bounded and the next capture clears it.
    }
  }

  Future<void> _start() async {
    if (_busy) return;
    final slots = widget.connectedSlots().toList()
      ..sort((a, b) => b.compareTo(a));
    if (slots.isEmpty) return;
    setState(() {
      _trial.clear();
      for (final slot in slots) {
        _trial[slot] = _SockTrial();
      }
      _issue = null;
      _finished = false;
      _guidance = false;
      _calibrationQueue.clear();
      _calibrationError = null;
      _remaining = _seconds;
      _captureOpen = true;
    });
    try {
      await SensoriaApi.setTrialCapture(true);
      if (!mounted || !_captureOpen) return;
      _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || !_captureOpen) return;
        setState(() => _remaining = _seconds - timer.tick);
        if (_remaining == 0) {
          timer.cancel();
          unawaited(_update());
        }
      });
    } catch (error) {
      _logCaptureError(error);
      if (mounted) await _stop(issue: _TrialIssue.unavailable);
    }
  }

  Future<void> _update() async {
    if (!mounted || _reading) return;
    if (!_busy) {
      if (_calibrating) return;
      if (_finished && !_sameSocks()) {
        setState(() {
          _issue = _TrialIssue.disconnected;
          _guidance = false;
          _finished = false;
        });
      } else if (!_finished) {
        setState(() {});
      }
      return;
    }
    final capture = _countdown;
    if (!_captureOpen || capture == null) return;
    if (!_sameSocks()) {
      await _stop(issue: _TrialIssue.disconnected);
      return;
    }
    _reading = true;
    try {
      final samples = await SensoriaApi.drainTrialSamples();
      if (!mounted || !_captureOpen || _countdown != capture) return;
      if (!_sameSocks()) {
        await _stop(issue: _TrialIssue.disconnected);
        return;
      }
      for (final sample in samples) {
        if (sample
            case [
              int slot,
              int tick,
              int counterBits,
              int accelRange,
              int magRange,
              int packetPeriodMs,
              String row
            ]) {
          _trial[slot]?.accept(
              tick, counterBits, accelRange, magRange, packetPeriodMs, row);
        } else if (sample
            case [
              int slot,
              int tick,
              int counterBits,
              int accelRange,
              int magRange,
              String row
            ]) {
          _trial[slot]
              ?.accept(tick, counterBits, accelRange, magRange, 20, row);
        }
      }
      if (_remaining == 0) {
        await _stop();
      } else {
        setState(() {});
      }
    } catch (error) {
      _logCaptureError(error);
      if (mounted && _captureOpen) await _stop(issue: _TrialIssue.unavailable);
    } finally {
      _reading = false;
    }
  }

  bool _sameSocks() {
    final connected = widget.connectedSlots();
    return connected.length == _trial.length &&
        connected.containsAll(_trial.keys);
  }

  void _logCaptureError(Object error) {
    final code = error is PlatformException ? error.code : error.runtimeType;
    debugPrint('Sensoria trial capture failed ($code)');
  }

  Future<void> _stop({_TrialIssue? issue}) async {
    if (!_captureOpen) return;
    setState(() {
      _captureOpen = false;
      _closingCapture = true;
      _countdown?.cancel();
      _countdown = null;
    });
    await _disableCapture();
    if (!mounted) return;
    setState(() {
      _closingCapture = false;
      _finished = issue == null;
      _issue = issue;
    });
  }

  String _foot(int slot) => slot == 1
      ? tr('Right sock', 'Calcetín derecho')
      : tr('Left sock', 'Calcetín izquierdo');

  String _warning() {
    if (_issue != null) {
      return switch (_issue!) {
        _TrialIssue.disconnected => tr(
            'A sock disconnected. Go back and reconnect it.',
            'Se desconectó un calcetín. Vuelve atrás y conéctalo.',
          ),
        _TrialIssue.unavailable => tr(
            'We couldn’t read the socks. Please try again.',
            'No pudimos leer los calcetines. Inténtalo de nuevo.',
          ),
        _TrialIssue.interrupted => tr(
            'Keep HealthyWear open while you walk.',
            'Mantén HealthyWear abierto mientras caminas.',
          ),
      };
    }
    return _trial.entries
        .where((entry) => !entry.value.walkPassed)
        .map((entry) {
      final reading = entry.value;
      final reason = reading.samples == 0
          ? tr('No readings', 'Sin lecturas')
          : reading.unstableConnection
              ? tr('The connection was unstable', 'La conexión fue inestable')
              : reading.accelerationClipped
                  ? tr('Movement reached the sensor limit',
                      'El movimiento alcanzó el límite del sensor')
                  : !reading.hasPressureSignal
                      ? tr('Adjust the sock and try again.',
                          'Ajusta el calcetín y vuelve a intentarlo.')
                      : tr('Take a few steps at your usual pace.',
                          'Da unos pasos a tu ritmo habitual.');
      return '${_foot(entry.key)}. $reason';
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    if (_guidance) return _buildGuidance();
    final walkPassed = _finished &&
        _trial.isNotEmpty &&
        _trial.values.every((reading) => reading.walkPassed);
    final calibration = walkPassed && _magneticIssues.isNotEmpty;
    final ready = walkPassed && !calibration;
    final result = _issue != null || _finished;
    final title = ready
        ? tr('You’re ready', 'Todo listo')
        : calibration
            ? tr('Calibration needed', 'Hay que calibrar')
            : result
                ? tr('Let’s try again', 'Vamos a intentarlo de nuevo')
                : _busy
                    ? tr('Keep walking', 'Sigue caminando')
                    : tr('Put on your socks', 'Ponte los calcetines');
    final icon = ready
        ? Icons.check_rounded
        : calibration
            ? Icons.close_rounded
            : Icons.refresh_rounded;
    final color = ready ? _green : _red;

    return Scaffold(
      backgroundColor: const Color(0xfff2f6fc),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(tr('Walking trial', 'Prueba de marcha')),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 34)),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (result)
                        Center(child: _TrialMark(icon: icon, color: color))
                      else
                        _MovementIllustration(magnetic: false),
                      const SizedBox(height: 28),
                      Text(title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: _navy)),
                      const SizedBox(height: 12),
                      Text(
                        ready
                            ? tr('Tap Start to begin recording.',
                                'Pulsa Iniciar para empezar a grabar.')
                            : calibration
                                ? tr(
                                    '${_magneticIssues.map(_foot).join(' and ')} ${_magneticIssues.length == 1 ? 'needs' : 'need'} calibration.',
                                    '${_magneticIssues.map(_foot).join(' y ')}: ${_magneticIssues.length == 1 ? 'necesita' : 'necesitan'} calibración.')
                                : result
                                    ? _warning()
                                    : _busy
                                        ? tr(
                                            'Take a few more steps at your usual pace.',
                                            'Da unos pasos más a tu ritmo habitual.')
                                        : tr(
                                            'Tap Go, then take a few steps at your usual pace.',
                                            'Pulsa Vamos y da unos pasos a tu ritmo habitual.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 19,
                            color: result && !ready ? _red : _navy),
                      ),
                      const SizedBox(height: 25),
                      if (_busy) ...[
                        LinearProgressIndicator(
                          value: (_seconds - _remaining) / _seconds,
                          minHeight: 10,
                          color: _navy,
                          backgroundColor: const Color(0xffd8e5f5),
                          borderRadius: BorderRadius.circular(8),
                          semanticsLabel:
                              tr('Trial progress', 'Progreso de la prueba'),
                        ),
                        const SizedBox(height: 10),
                        Text(
                            tr('$_remaining seconds left',
                                'Quedan $_remaining segundos'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 17, color: _navy)),
                      ] else if (ready)
                        _primary(
                            tr('Start', 'Iniciar'),
                            Icons.play_arrow_rounded,
                            _sameSocks()
                                ? () => Navigator.pop(context, true)
                                : null)
                      else if (calibration)
                        _primary(
                            tr('Calibration', 'Calibración'),
                            Icons.arrow_forward_rounded,
                            () => setState(() {
                                  _calibrationQueue
                                    ..clear()
                                    ..addAll(_magneticIssues);
                                  _guidance = true;
                                  _sockCalibrated = false;
                                  _calibrationError = null;
                                }))
                      else if (result)
                        _primary(
                            tr('Repeat trial', 'Repetir prueba'),
                            Icons.refresh_rounded,
                            widget.connectedSlots().isEmpty ? null : _start)
                      else
                        Center(
                          child: SizedBox.square(
                            dimension: 108,
                            child: ElevatedButton(
                              onPressed: widget.connectedSlots().isEmpty
                                  ? null
                                  : _start,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                                elevation: 6,
                                shadowColor: const Color(0x80153865),
                                shape: const CircleBorder(),
                                backgroundColor: _navy,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                    fontSize: 21, fontWeight: FontWeight.w800),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  tr('Go', 'Vamos'),
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  softWrap: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _notice(String message) => DecoratedBox(
        decoration: BoxDecoration(
            color: const Color(0xffffe9ec),
            borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.error_outline_rounded, color: _red),
            const SizedBox(width: 9),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        color: _red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600))),
          ]),
        ),
      );

  Widget _primary(String label, IconData icon, VoidCallback? onPressed) =>
      FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, textAlign: TextAlign.center),
        style: FilledButton.styleFrom(
          backgroundColor: _navy,
          minimumSize: const Size.fromHeight(58),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      );

  Future<void> _startCalibration() async {
    if (_calibrating || _sockCalibrated || _calibrationQueue.isEmpty) return;
    final slot = _calibrationQueue.first;
    setState(() {
      _calibrating = true;
      _calibrationError = null;
    });
    String result;
    try {
      result = await SensoriaApi.calibrateMagnetometer(slot);
    } catch (error) {
      _logCaptureError(error);
      result = 'unavailable';
    }
    if (!mounted) return;
    setState(() {
      _calibrating = false;
      if (result == 'success') {
        _sockCalibrated = true;
      } else {
        _calibrationError = !widget.connectedSlots().contains(slot)
            ? tr('Reconnect this sock and try again.',
                'Vuelve a conectar este calcetín e inténtalo de nuevo.')
            : switch (result) {
                'retry' => tr('Try again with wider turns.',
                    'Inténtalo de nuevo con giros más amplios.'),
                'commandFailed' => tr(
                    'The sock couldn’t start calibration. Try again.',
                    'El calcetín no pudo iniciar la calibración. Inténtalo de nuevo.'),
                'offsetsOutOfRange' => tr(
                    'Calibration is still out of range. Try again.',
                    'La calibración sigue fuera de rango. Inténtalo de nuevo.'),
                _ => tr('We couldn’t confirm calibration. Try again.',
                    'No pudimos confirmar la calibración. Inténtalo de nuevo.'),
              };
      }
    });
  }

  Widget _buildGuidance() {
    final failed = _calibrationError != null;
    final title = _sockCalibrated
        ? tr('Calibration successful', 'Calibración completada')
        : _calibrating
            ? tr('Keep moving the sock', 'Sigue moviendo el calcetín')
            : failed
                ? tr('Calibration failed', 'No se pudo calibrar')
                : tr('Sock calibration', 'Calibración del calcetín');
    final slot = _calibrationQueue.isEmpty ? null : _calibrationQueue.first;
    final canStart = slot != null && widget.connectedSlots().contains(slot);
    final hasNextSock = _calibrationQueue.length > 1;
    return PopScope(
      canPop: !_calibrating,
      child: Scaffold(
        backgroundColor: const Color(0xfff2f6fc),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: _calibrating
              ? const SizedBox.shrink()
              : BackButton(
                  onPressed: () {
                    if (widget.calibrationSlot != null) {
                      Navigator.pop(context);
                    } else {
                      setState(() => _guidance = false);
                    }
                  },
                ),
          title: Text(tr('Calibration', 'Calibración')),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const SizedBox(height: 18),
              if (_sockCalibrated)
                const Center(
                    child: _TrialMark(icon: Icons.check_rounded, color: _green))
              else if (failed)
                const Center(
                    child: _TrialMark(icon: Icons.close_rounded, color: _red))
              else
                const _MovementIllustration(magnetic: true),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 9),
              if (slot != null)
                Text(_foot(slot),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    )),
              const SizedBox(height: 14),
              if (_sockCalibrated && hasNextSock)
                _primary(
                  tr('Next sock', 'Siguiente calcetín'),
                  Icons.arrow_forward_rounded,
                  () => setState(() {
                    _calibrationQueue.removeAt(0);
                    _sockCalibrated = false;
                  }),
                )
              else if (_sockCalibrated) ...[
                Text(
                    tr('Put your socks back on.',
                        'Vuelve a ponerte los calcetines.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _navy, fontSize: 21)),
                const SizedBox(height: 24),
                _primary(
                    widget.calibrationSlot != null
                        ? tr('Done', 'Listo')
                        : tr('Start test', 'Iniciar prueba'),
                    widget.calibrationSlot != null
                        ? Icons.check
                        : Icons.play_arrow_rounded,
                    widget.calibrationSlot != null || _sameSocks()
                        ? () => Navigator.pop(context, true)
                        : null),
              ] else if (_calibrating) ...[
                Text(
                    tr('Make wide figure eights. Tilt and flip the sock as you go.',
                        'Dibuja ochos amplios. Inclina y gira el calcetín mientras lo mueves.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _navy, fontSize: 19)),
                const SizedBox(height: 24),
                const LinearProgressIndicator(),
              ] else if (failed) ...[
                _notice(_calibrationError!),
                const SizedBox(height: 24),
                _primary(tr('Retry calibration', 'Reintentar calibración'),
                    Icons.refresh_rounded, canStart ? _startCalibration : null),
              ] else ...[
                _calibrationStep(
                    Icons.airline_seat_recline_normal_rounded,
                    tr('Sit down and remove the sock. Leave the sensor attached.',
                        'Siéntate y quítate el calcetín. Deja el sensor colocado.')),
                _calibrationStep(
                    Icons.phonelink_off_rounded,
                    tr('Move away from metal and phones.',
                        'Aléjate del metal y de los teléfonos.')),
                _calibrationStep(
                    Icons.all_inclusive_rounded,
                    tr('Make slow figure eights. Tilt and flip as you move.',
                        'Dibuja ochos lentos. Inclina y gira el calcetín al moverlo.')),
                const SizedBox(height: 24),
                _primary(
                    tr('Start calibration', 'Iniciar calibración'),
                    Icons.play_arrow_rounded,
                    canStart ? _startCalibration : null),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _calibrationStep(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: const Color(0xffdceafa),
            foregroundColor: _navy,
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: _navy, fontSize: 18))),
        ]),
      );
}

class _SockTrial {
  static const _windowMs = 100;
  static const _stepWindowMs = 500;
  static const _contactDrop = 6;
  // The previous threshold at ±8 g was two counts (0.03125 g).
  static const _movementDeltaG = 0.03125;
  int samples = 0;
  int _missed = 0;
  int? _lastTick;
  bool get unstableConnection =>
      _missed > 5 && _missed * 10 > samples + _missed;
  bool hasPressureSignal = false;
  bool _hasStepResponse = false;
  bool _magneticClipped = false;
  bool accelerationClipped = false;
  int _magneticNonzero = 0;
  final _motionWindow = <List<double>>[];
  final _recentReadings = <List<double>>[];

  bool get walkPassed =>
      samples > 0 &&
      _hasStepResponse &&
      !accelerationClipped &&
      !unstableConnection;
  bool get hasMagneticIssue =>
      _magneticClipped || (samples > 0 && _magneticNonzero == 0);

  void accept(int tick, int counterBits, int accelRange, int magRange,
      int packetPeriodMs, String row) {
    final fields = row.split(',');
    if (fields.length != 13) return;
    final values = fields.take(9).map(double.tryParse).toList();
    if (values.any((v) => v == null || !v.isFinite)) return;
    final v = values.cast<double>();
    final lastTick = _lastTick;
    if (lastTick != null && (counterBits == 18 || counterBits == 24)) {
      final size = 1 << counterBits;
      final gap = (tick - lastTick) & (size - 1);
      if (gap > 1 && gap < size ~/ 2) {
        _missed += gap - 1;
        if ((gap - 1) * packetPeriodMs >= _windowMs) {
          _motionWindow.clear();
          _recentReadings.clear();
        }
      }
    }
    _lastTick = tick;
    samples++;
    for (var axis = 0; axis < 3; axis++) {
      final acceleration = v[axis + 3];
      accelerationClipped |= acceleration >= accelRange * 511 / 512 - .0001 ||
          acceleration <= -accelRange + .0001;
    }
    _checkResponse(v, packetPeriodMs.clamp(5, 200));
    // The Core 1 SDKs scale the signed 10-bit readings before sending them to Dart.
    final scale = 0.009344 * magRange / 4;
    final mag = v.skip(6);
    if (mag.any((axis) => axis != 0)) _magneticNonzero++;
    _magneticClipped |= scale > 0 &&
        mag.any((axis) => axis >= 510.5 * scale || axis <= -511.5 * scale);
  }

  void _checkResponse(List<double> sample, int packetPeriodMs) {
    if (_hasStepResponse) return;
    final windowSize = (_windowMs / packetPeriodMs).round().clamp(3, 20);
    _motionWindow.add(sample);
    if (_motionWindow.length < windowSize) return;

    final medians = List.generate(6, (channel) {
      final readings = _motionWindow.map((row) => row[channel]).toList()
        ..sort();
      return readings[windowSize ~/ 2];
    });
    _motionWindow.clear();
    _recentReadings.add(medians);
    final recentWindows =
        (_stepWindowMs / (windowSize * packetPeriodMs)).round().clamp(2, 5);
    if (_recentReadings.length > recentWindows) _recentReadings.removeAt(0);
    if (_recentReadings.length < 2) return;

    // Sensoria's pressure counts fall when loaded. Look for a contact and
    // nearby movement on this sock instead of combining unrelated peaks.
    final contact = Iterable<int>.generate(3).any((channel) {
      final current = medians[channel];
      return current > 0 &&
          current < 1023 &&
          _recentReadings.any((recent) {
            final previous = recent[channel];
            return previous < 1023 && previous - current >= _contactDrop;
          });
    });
    if (!contact) return;
    hasPressureSignal = true;
    _hasStepResponse =
        Iterable<int>.generate(3, (axis) => axis + 3).any((axis) {
      final readings = _recentReadings.map((window) => window[axis]);
      return readings.reduce(math.max) - readings.reduce(math.min) >=
          _movementDeltaG - 0.000001;
    });
  }
}

class _TrialMark extends StatelessWidget {
  const _TrialMark({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey(icon),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 460),
        curve: Curves.easeOutBack,
        tween: Tween(begin: .65, end: 1),
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: CircleAvatar(
          radius: 68,
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, size: 79, color: color),
        ),
      );
}

class SensoriaSockIllustration extends StatelessWidget {
  const SensoriaSockIllustration({super.key});

  @override
  Widget build(BuildContext context) => const CustomPaint(
        size: Size(68, 68),
        painter: _SensoriaSockPainter(),
      );
}

class _SensoriaSockPainter extends CustomPainter {
  const _SensoriaSockPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width * .34, size.height * .49);
    canvas.scale(size.height / 80);
    _drawSock(canvas, const Color(0xffbedcff));
  }

  @override
  bool shouldRepaint(_SensoriaSockPainter oldDelegate) => false;
}

void _drawSock(Canvas canvas, Color color) {
  final paint = Paint();
  final sock = Path()
    ..moveTo(-13, -33)
    ..lineTo(13, -33)
    ..lineTo(13, 3)
    ..quadraticBezierTo(13, 10, 21, 10)
    ..lineTo(30, 10)
    ..quadraticBezierTo(44, 10, 44, 22)
    ..quadraticBezierTo(44, 32, 31, 33)
    ..lineTo(0, 33)
    ..quadraticBezierTo(-13, 33, -13, 20)
    ..close();
  canvas.drawPath(sock, paint..color = color);
  paint.color = const Color(0xff153f76);
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6, -24, 15, 22), const Radius.circular(4)),
      paint);
  paint.color = const Color(0xffddedff);
  canvas.drawCircle(const Offset(1.5, -16), 2.5, paint);
}

class _MovementIllustration extends StatefulWidget {
  const _MovementIllustration({required this.magnetic});
  final bool magnetic;

  @override
  State<_MovementIllustration> createState() => _MovementIllustrationState();
}

class _MovementIllustrationState extends State<_MovementIllustration>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(vsync: this);

  void _updateMotion() {
    _motion.duration = widget.magnetic
        ? const Duration(seconds: 4)
        : const Duration(milliseconds: 1750);
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
    } else {
      _motion.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void didUpdateWidget(covariant _MovementIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.magnetic != widget.magnetic) {
      _updateMotion();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ColoredBox(
            color: const Color(0xff102c54),
            child: SizedBox(
              height: 154,
              child: AnimatedBuilder(
                animation: _motion,
                builder: (_, __) => CustomPaint(
                  painter: _MovementPainter(_motion.value, widget.magnetic),
                ),
              ),
            ),
          ),
        ),
      );
}

class _MovementPainter extends CustomPainter {
  const _MovementPainter(this.progress, this.magnetic);
  final double progress;
  final bool magnetic;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final paint = Paint()..color = const Color(0xff9cc9ff);
    if (magnetic) {
      final phase = progress * 2 * math.pi;
      {
        final path = Path();
        for (var i = 0; i <= 96; i++) {
          final t = i * math.pi / 48;
          final x = 83 * math.sin(t);
          final y = 33 * math.sin(2 * t);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xff517caf)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        canvas.translate(83 * math.sin(phase), 33 * math.sin(2 * phase));
        canvas.rotate(0.6 * math.sin(phase));
        final flip = math.cos(phase);
        canvas.scale((flip < 0 ? -1 : 1) * (0.22 + .78 * flip.abs()), 1);
      }
      _drawSock(canvas, paint.color);
    } else {
      final ink = const Color(0xffd7eaff);
      final accent = const Color(0xff69c7e8);
      final ground = Paint()
        ..color = const Color(0xff36567e)
        ..strokeWidth = 1.5;
      canvas.drawLine(const Offset(-91, 57), const Offset(91, 57), ground);
      final stride = progress * 2 * math.pi;
      final rise = 1.5 * math.cos(2 * stride);
      final hip = Offset(-6, 10 + rise);
      final shoulder = Offset(-3, -24 + rise);
      final stroke = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      void drawLeg(double t, Color color) {
        final travel = t < .6 ? 15 - 30 * t / .6 : -15 + 30 * (t - .6) / .4;
        final lift = t < .6 ? 0.0 : 9 * math.sin(math.pi * (t - .6) / .4);
        final ankle = Offset(hip.dx + travel, 51 - lift);
        final knee =
            Offset((hip.dx + ankle.dx) / 2 + 5 + lift * .3, 31 - lift * .25);
        final leg = Path()
          ..moveTo(hip.dx, hip.dy)
          ..lineTo(knee.dx, knee.dy)
          ..lineTo(ankle.dx, ankle.dy);
        canvas.drawPath(
            leg,
            stroke
              ..color = color
              ..strokeWidth = 7);
        canvas.drawLine(
            ankle,
            ankle + Offset(8, t < .6 ? 3 : 1),
            stroke
              ..color = accent
              ..strokeWidth = 4);
      }

      void drawArm(double direction, Color color) {
        final swing = math.sin(stride) * direction;
        final elbow = shoulder + Offset(7 * swing - 2, 14);
        final hand = elbow + Offset(7 * swing + 5, 10);
        final arm = Path()
          ..moveTo(shoulder.dx, shoulder.dy)
          ..lineTo(elbow.dx, elbow.dy)
          ..lineTo(hand.dx, hand.dy);
        canvas.drawPath(
            arm,
            stroke
              ..color = color
              ..strokeWidth = 4.5);
      }

      drawArm(-1, const Color(0xff719cc6));
      drawLeg((progress + .5) % 1, const Color(0xff719cc6));
      canvas.drawLine(
          hip,
          shoulder,
          stroke
            ..color = ink
            ..strokeWidth = 12);
      canvas.drawCircle(
          shoulder + const Offset(4, -15), 8.5, Paint()..color = ink);
      drawLeg(progress % 1, ink);
      drawArm(1, ink);

      final direction = Path()
        ..moveTo(43, 13)
        ..lineTo(72, 13)
        ..moveTo(66, 7)
        ..lineTo(72, 13)
        ..lineTo(66, 19);
      canvas.drawPath(
          direction,
          stroke
            ..color = accent
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_MovementPainter oldDelegate) =>
      progress != oldDelegate.progress || magnetic != oldDelegate.magnetic;
}
