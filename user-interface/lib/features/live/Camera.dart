import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/widgets.dart';

/// Centralised camera manager for Windows that wraps the low level
/// camera platform API behind an easy to reuse class.
class CameraService {
  CameraService._internal();

  /// Singleton instance so the same camera session can be reused everywhere.
  static final CameraService instance = CameraService._internal();

  final StreamController<CameraErrorEvent> _errorController =
      StreamController<CameraErrorEvent>.broadcast();
  final StreamController<CameraClosingEvent> _closingController =
      StreamController<CameraClosingEvent>.broadcast();

  List<CameraDescription> _cameras = const <CameraDescription>[];
  int _cameraIndex = 0;
  int? _cameraId;
  bool _initialized = false;
  Size? _previewSize;
  MediaSettings _mediaSettings = const MediaSettings(
    resolutionPreset: ResolutionPreset.low,
    fps: 1,
    videoBitrate: 200000,
    audioBitrate: 32000,
    enableAudio: true,
  );

  StreamSubscription<CameraErrorEvent>? _errorSubscription;
  StreamSubscription<CameraClosingEvent>? _closingSubscription;

  /// Exposes camera errors to listeners.
  Stream<CameraErrorEvent> get onError => _errorController.stream;

  /// Exposes camera closing events to listeners.
  Stream<CameraClosingEvent> get onClosing => _closingController.stream;

  /// Returns the list of cached cameras.
  List<CameraDescription> get cameras => _cameras;

  /// Returns the currently selected camera description.
  CameraDescription? get currentCamera =>
      _cameras.isEmpty ? null : _cameras[_cameraIndex % _cameras.length];

  /// Indicates whether the camera has been successfully initialised.
  bool get isInitialized => _initialized;

  /// The identifier for the active camera.
  int? get cameraId => _cameraId;

  /// Size of the current preview, if initialised.
  Size? get previewSize => _previewSize;

  /// Current media settings used for initialisation.
  MediaSettings get mediaSettings => _mediaSettings;

  /// Fetches the available cameras and caches the list.
  Future<List<CameraDescription>> fetchCameras() async {
    _cameras = await CameraPlatform.instance.availableCameras();
    if (_cameras.isEmpty) {
      throw StateError('No cameras are available on this device.');
    }
    _cameraIndex = _cameraIndex % _cameras.length;
    return _cameras;
  }

  /// Initialises the camera with the cached settings.
  Future<void> initialize({MediaSettings? settings, int? cameraIndex}) async {
    if (_initialized) {
      return;
    }

    if (settings != null) {
      _mediaSettings = settings;
    }

    if (_cameras.isEmpty) {
      await fetchCameras();
      print("Cameras found: ${_cameras.length}");
    }

    _cameraIndex = cameraIndex ?? _cameraIndex;
    await _createCamera(_cameraIndex % _cameras.length);
    print("Camera initialized: ${currentCamera?.name}");
  }

  /// Releases camera resources.
  Future<void> dispose() async {
    await _disposeCurrentCamera();
    await _errorSubscription?.cancel();
    await _closingSubscription?.cancel();
    _errorSubscription = null;
    _closingSubscription = null;
  }

  /// Builds the plugin preview widget for the current camera.
  Widget buildPreview() {
    final int? id = _cameraId;
    if (!_initialized || id == null) {
      throw StateError('Camera preview requested before initialisation.');
    }
    return CameraPlatform.instance.buildPreview(id);
  }

  /// Captures a still image.
  Future<XFile> takePicture() async {
    final int? id = _cameraId;
    if (!_initialized || id == null) {
      throw StateError('Cannot take a picture before the camera is ready.');
    }
    return CameraPlatform.instance.takePicture(id);
  }

  /// Pauses the live preview feed.
  Future<void> pausePreview() async {
    final int? id = _cameraId;
    if (_initialized && id != null) {
      await CameraPlatform.instance.pausePreview(id);
    }
  }

  /// Resumes the live preview feed.
  Future<void> resumePreview() async {
    final int? id = _cameraId;
    if (_initialized && id != null) {
      await CameraPlatform.instance.resumePreview(id);
    }
  }

  /// Switches to the next available camera or to [index] if supplied.
  Future<void> switchCamera({int? index}) async {
    if (_cameras.isEmpty) {
      await fetchCameras();
    }
    _cameraIndex = index ?? (_cameraIndex + 1) % _cameras.length;
    await _reopenCamera();
  }

  /// Updates media settings and reinitialises the camera.
  Future<void> updateMediaSettings(MediaSettings settings) async {
    _mediaSettings = settings;
    await _reopenCamera();
  }

  /// Internal helper to reinitialise the current camera with new parameters.
  Future<void> _reopenCamera() async {
    await _disposeCurrentCamera();
    if (_cameras.isEmpty) {
      await fetchCameras();
    }
    await _createCamera(_cameraIndex % _cameras.length);
  }

  Future<void> _createCamera(int index) async {
    int? cameraId;
    try {
      final CameraDescription camera = _cameras[index];
      cameraId = await CameraPlatform.instance.createCameraWithSettings(
        camera,
        _mediaSettings,
      );

      await _errorSubscription?.cancel();
      _errorSubscription = CameraPlatform.instance
          .onCameraError(cameraId)
          .listen(_errorController.add);

      await _closingSubscription?.cancel();
      _closingSubscription = CameraPlatform.instance
          .onCameraClosing(cameraId)
          .listen(_closingController.add);

      final initializedFuture =
        CameraPlatform.instance.onCameraInitialized(cameraId).first;

        await CameraPlatform.instance.initializeCamera(cameraId);
        final CameraInitializedEvent event = await initializedFuture;

      _previewSize = Size(event.previewWidth, event.previewHeight);
      _cameraId = cameraId;
      _cameraIndex = index;
      _initialized = true;
    } on CameraException catch (e) {
        print("Camera initialization failed." + e.toString());
      if (cameraId != null) {
        await _safeDispose(cameraId);
      }
      rethrow;
    }
  }

  Future<void> _disposeCurrentCamera() async {
    final int? id = _cameraId;
    if (_initialized && id != null) {
      try {
        await CameraPlatform.instance.dispose(id);
      } finally {
        _initialized = false;
        _cameraId = null;
        _previewSize = null;
      }
    }
  }

  Future<void> _safeDispose(int cameraId) async {
    try {
      await CameraPlatform.instance.dispose(cameraId);
    } on CameraException {
      // Ignore disposal errors to avoid masking the original failure.
    }
  }
}
