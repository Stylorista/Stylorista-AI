import 'dart:typed_data';

import 'package:camera/camera.dart' as camera;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../services/stylorista_api.dart';
import '../theme/stylorista_theme.dart';
import '../widgets/common.dart';

class CameraMeasurementScreen extends StatefulWidget {
  const CameraMeasurementScreen({
    super.key,
    required this.api,
    required this.active,
    required this.onBack,
    required this.onMeasurementsReady,
    required this.onOpenShop,
  });

  final StyloristaApi api;
  final bool active;
  final VoidCallback onBack;
  final ValueChanged<Map<String, double>> onMeasurementsReady;
  final VoidCallback onOpenShop;

  @override
  State<CameraMeasurementScreen> createState() =>
      _CameraMeasurementScreenState();
}

class _CameraMeasurementScreenState extends State<CameraMeasurementScreen>
    with WidgetsBindingObserver {
  final _heightController = TextEditingController(text: '165');
  final _picker = picker.ImagePicker();

  camera.CameraController? _cameraController;
  List<camera.CameraDescription> _cameras = const [];
  Uint8List? _photoBytes;
  Map<String, dynamic>? _result;
  String? _error;
  bool _cameraStarting = false;
  bool _analyzing = false;
  bool _consentConfirmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) _startCamera();
  }

  @override
  void didUpdateWidget(covariant CameraMeasurementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active && _photoBytes == null) {
      _startCamera();
    } else if (!widget.active && oldWidget.active) {
      _disposeCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.active) return;
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed && _photoBytes == null) {
      _startCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heightController.dispose();
    _disposeCamera();
    super.dispose();
  }

  void _disposeCamera() {
    final controller = _cameraController;
    _cameraController = null;
    controller?.dispose();
  }

  Future<void> _startCamera({camera.CameraLensDirection? lens}) async {
    if (_cameraStarting || _cameraController?.value.isInitialized == true) {
      return;
    }
    setState(() {
      _cameraStarting = true;
      _error = null;
    });
    try {
      _cameras = await camera.availableCameras();
      if (_cameras.isEmpty) throw Exception('No camera found');
      final preferredLens = lens ?? camera.CameraLensDirection.back;
      final selected = _cameras.firstWhere(
        (item) => item.lensDirection == preferredLens,
        orElse: () => _cameras.first,
      );
      final controller = camera.CameraController(
        selected,
        camera.ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: camera.ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted || !widget.active) {
        await controller.dispose();
        return;
      }
      setState(() => _cameraController = controller);
    } on Exception {
      if (mounted) {
        setState(() {
          _error =
              'Camera preview is unavailable. Allow camera access or choose a full-body photo instead.';
        });
      }
    } finally {
      if (mounted) setState(() => _cameraStarting = false);
    }
  }

  Future<void> _switchCamera() async {
    final current = _cameraController?.description.lensDirection;
    final next = current == camera.CameraLensDirection.front
        ? camera.CameraLensDirection.back
        : camera.CameraLensDirection.front;
    _disposeCamera();
    await _startCamera(lens: next);
  }

  bool get _hasValidCalibration {
    final height = double.tryParse(_heightController.text.trim());
    return height != null && height >= 120 && height <= 230;
  }

  Future<bool> _ensureCalibration() async {
    if (_consentConfirmed && _hasValidCalibration) return true;
    var consent = _consentConfirmed;
    String? validationError;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            4,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Prepare your AI body scan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              const Text(
                'A normal photo has no centimetre scale. Enter your height once so AI can estimate the other measurements.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _heightController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Reference height',
                  suffixText: 'cm',
                ),
              ),
              CheckboxListTile(
                value: consent,
                onChanged: (value) =>
                    setSheetState(() => consent = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I consent to sending this photo to the configured scan API for in-memory analysis.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              if (validationError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    validationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: () {
                  if (!_hasValidCalibration) {
                    setSheetState(
                      () => validationError =
                          'Enter a reference height from 120–230 cm.',
                    );
                  } else if (!consent) {
                    setSheetState(
                      () => validationError =
                          'Consent is required before the photo is analyzed.',
                    );
                  } else {
                    Navigator.of(sheetContext).pop(true);
                  }
                },
                child: const Text('Continue to photo'),
              ),
            ],
          ),
        ),
      ),
    );
    if (accepted == true && mounted) {
      setState(() => _consentConfirmed = true);
      return true;
    }
    return false;
  }

  Future<void> _capture() async {
    if (!await _ensureCalibration()) return;
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      await _choosePhoto(picker.ImageSource.camera);
      return;
    }
    try {
      final file = await controller.takePicture();
      await _usePhoto(await file.readAsBytes());
    } on Exception {
      if (mounted) setState(() => _error = 'The photo could not be captured.');
    }
  }

  Future<void> _choosePhoto(picker.ImageSource source) async {
    if (!await _ensureCalibration()) return;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 2400,
        imageQuality: 88,
        requestFullMetadata: false,
      );
      if (file != null) await _usePhoto(await file.readAsBytes());
    } on Exception {
      if (mounted) {
        setState(() => _error = 'The selected photo could not be opened.');
      }
    }
  }

  Future<void> _usePhoto(Uint8List bytes) async {
    _disposeCamera();
    setState(() {
      _photoBytes = bytes;
      _result = null;
      _analyzing = true;
      _error = null;
    });
    try {
      final result = await widget.api.analyzeBodyPhoto(
        imageBytes: bytes,
        referenceHeightCm: double.parse(_heightController.text.trim()),
      );
      if (!mounted) return;
      final measurements = (result['measurements'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
      setState(() => _result = result);
      widget.onMeasurementsReady(measurements);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _retake() async {
    setState(() {
      _photoBytes = null;
      _result = null;
      _error = null;
    });
    await _startCamera();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFBFAF7),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ScanHeader(),
                const SizedBox(height: 22),
                _ScanViewport(
                  cameraController: _cameraController,
                  cameraStarting: _cameraStarting,
                  photoBytes: _photoBytes,
                  analyzing: _analyzing,
                  result: _result,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  ErrorBanner(message: _error!),
                ],
                const SizedBox(height: 18),
                _CameraControls(
                  captured: _photoBytes != null,
                  cameraReady: _cameraController?.value.isInitialized == true,
                  busy: _analyzing,
                  onBack: widget.onBack,
                  onCapture: _capture,
                  onRetake: _retake,
                  onGallery: () => _choosePhoto(picker.ImageSource.gallery),
                  onSwitch: _cameras.length > 1 ? _switchCamera : null,
                ),
                const SizedBox(height: 8),
                Text(
                  _consentConfirmed
                      ? 'Scale calibrated to ${_heightController.text} cm • Photo is processed in memory.'
                      : 'Height calibration and photo consent are requested before the first scan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 26),
                  _MeasurementResults(
                    result: _result!,
                    onOpenShop: widget.onOpenShop,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanHeader extends StatelessWidget {
  const _ScanHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          'Stylorista-AI',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 25,
            fontWeight: FontWeight.w500,
            letterSpacing: -1,
          ),
        ),
        Spacer(),
        Icon(Icons.menu_rounded, size: 29),
      ],
    );
  }
}

class _ScanViewport extends StatelessWidget {
  const _ScanViewport({
    required this.cameraController,
    required this.cameraStarting,
    required this.photoBytes,
    required this.analyzing,
    required this.result,
  });

  final camera.CameraController? cameraController;
  final bool cameraStarting;
  final Uint8List? photoBytes;
  final bool analyzing;
  final Map<String, dynamic>? result;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE9D1BA), Color(0xFFC6976D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            if (photoBytes != null)
              Image.memory(photoBytes!, fit: BoxFit.cover)
            else if (cameraController?.value.isInitialized == true)
              camera.CameraPreview(cameraController!)
            else
              _EmptyCamera(cameraStarting: cameraStarting),
            CustomPaint(painter: _CameraGuidePainter()),
            if (result == null && !analyzing)
              const Center(
                child: Icon(
                  Icons.crop_free_rounded,
                  size: 70,
                  color: Colors.white70,
                ),
              ),
            if (result != null) _BodyLabels(result: result!),
            if (analyzing)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'AI is mapping your silhouette…',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Positioned(
              left: 24,
              right: 24,
              top: 19,
              child: Text(
                'FRONT VIEW  •  HEAD TO TOE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCamera extends StatelessWidget {
  const _EmptyCamera({required this.cameraStarting});

  final bool cameraStarting;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cameraStarting)
            const CircularProgressIndicator(color: Colors.white)
          else
            const Icon(
              Icons.accessibility_new_rounded,
              size: 150,
              color: Colors.white54,
            ),
          const SizedBox(height: 18),
          Text(
            cameraStarting
                ? 'Starting camera…'
                : 'Stand against a plain background',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyLabels extends StatelessWidget {
  const _BodyLabels({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final values = result['measurements'] as Map<String, dynamic>;
    String value(String key) => '${(values[key] as num).toStringAsFixed(1)} cm';

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          _ScanLabel(
            top: constraints.maxHeight * 0.16,
            left: constraints.maxWidth * 0.05,
            text: 'Height  ${value('height')}',
          ),
          _ScanLabel(
            top: constraints.maxHeight * 0.25,
            right: constraints.maxWidth * 0.04,
            text: 'Shoulder  ${value('shoulder')}',
          ),
          _ScanLabel(
            top: constraints.maxHeight * 0.35,
            left: constraints.maxWidth * 0.04,
            text: 'Chest  ${value('chest')}',
          ),
          _ScanLabel(
            top: constraints.maxHeight * 0.48,
            right: constraints.maxWidth * 0.04,
            text: 'Waist  ${value('waist')}',
          ),
          _ScanLabel(
            top: constraints.maxHeight * 0.59,
            left: constraints.maxWidth * 0.04,
            text: 'Hip  ${value('hip')}',
          ),
          _ScanLabel(
            top: constraints.maxHeight * 0.74,
            right: constraints.maxWidth * 0.04,
            text: 'Inseam  ${value('inseam')}',
          ),
        ],
      ),
    );
  }
}

class _ScanLabel extends StatelessWidget {
  const _ScanLabel({
    this.left,
    this.right,
    required this.top,
    required this.text,
  });

  final double? left;
  final double? right;
  final double top;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF4E3023).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white70),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CameraControls extends StatelessWidget {
  const _CameraControls({
    required this.captured,
    required this.cameraReady,
    required this.busy,
    required this.onBack,
    required this.onCapture,
    required this.onRetake,
    required this.onGallery,
    required this.onSwitch,
  });

  final bool captured;
  final bool cameraReady;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onCapture;
  final VoidCallback onRetake;
  final VoidCallback onGallery;
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF513225);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton.outlined(
          tooltip: 'Back home',
          onPressed: busy ? null : onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          iconSize: 31,
          style: IconButton.styleFrom(
            foregroundColor: StyloristaColors.sandText,
            side: const BorderSide(color: StyloristaColors.sandText, width: 2),
          ),
        ),
        Semantics(
          button: true,
          label: captured ? 'Retake photo' : 'Take photo',
          child: InkResponse(
            onTap: busy ? null : (captured ? onRetake : onCapture),
            radius: 59,
            child: Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                color: brown,
                shape: BoxShape.circle,
              ),
              child: Icon(
                captured ? Icons.refresh_rounded : Icons.photo_camera_outlined,
                color: Colors.white,
                size: 61,
              ),
            ),
          ),
        ),
        Column(
          children: [
            IconButton(
              tooltip: 'Choose photo',
              onPressed: busy ? null : onGallery,
              icon: const Icon(Icons.photo_library_outlined),
              color: brown,
            ),
            if (cameraReady)
              IconButton(
                tooltip: 'Switch camera',
                onPressed: busy ? null : onSwitch,
                icon: const Icon(Icons.cameraswitch_outlined),
                color: brown,
              ),
          ],
        ),
      ],
    );
  }
}

class _MeasurementResults extends StatelessWidget {
  const _MeasurementResults({required this.result, required this.onOpenShop});

  final Map<String, dynamic> result;
  final VoidCallback onOpenShop;

  static const labels = {
    'height': 'Height',
    'neck': 'Neck',
    'shoulder': 'Shoulder',
    'chest': 'Chest / bust',
    'underbust': 'Underbust',
    'waist': 'Natural waist',
    'high_hip': 'High hip',
    'hip': 'Full hip',
    'sleeve': 'Sleeve',
    'wrist': 'Wrist',
    'inseam': 'Inseam',
  };

  @override
  Widget build(BuildContext context) {
    final measurements = result['measurements'] as Map<String, dynamic>;
    final confidence = ((result['scan_confidence'] as num) * 100).round();
    final quality = ((result['image_quality'] as num) * 100).round();
    final warnings = (result['quality_warnings'] as List).cast<String>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI body profile',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text('Scan confidence $confidence%  •  Image quality $quality%'),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width < 420 ? 2 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.9,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              children: [
                for (final entry in labels.entries)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: StyloristaColors.sand.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(measurements[entry.key] as num).toStringAsFixed(1)} cm',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            for (final warning in warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 17,
                      color: StyloristaColors.sandText,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        warning,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Text(
              result['validation_status'] as String,
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result['disclaimer'] as String,
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onOpenShop,
              icon: const Icon(Icons.shopping_cart_rounded),
              label: const Text('Shop my AI fit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const inset = 20.0;
    const length = 79.0;
    final path = Path()
      ..moveTo(inset, inset + length)
      ..lineTo(inset, inset)
      ..lineTo(inset + length, inset)
      ..moveTo(size.width - inset - length, inset)
      ..lineTo(size.width - inset, inset)
      ..lineTo(size.width - inset, inset + length)
      ..moveTo(inset, size.height - inset - length)
      ..lineTo(inset, size.height - inset)
      ..lineTo(inset + length, size.height - inset)
      ..moveTo(size.width - inset - length, size.height - inset)
      ..lineTo(size.width - inset, size.height - inset)
      ..lineTo(size.width - inset, size.height - inset - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
