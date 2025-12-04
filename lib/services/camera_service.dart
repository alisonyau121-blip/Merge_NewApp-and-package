import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Service for managing camera initialization and control
/// Used exclusively for the ID Scanner Screen (Test Figma feature)
class CameraService {
  static final _log = Logger('CameraService');
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  
  /// Initialize the camera with high resolution
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        _log.info('Camera initialized successfully');
      } else {
        _log.warning('No cameras available on this device');
      }
    } catch (e) {
      _log.severe('Error initializing camera: $e');
    }
  }
  
  /// Get the camera controller
  CameraController? get controller => _cameraController;
  
  /// Check if camera is initialized
  bool get isInitialized => 
      _cameraController != null && _cameraController!.value.isInitialized;
  
  /// Take a picture and return the file path
  Future<String?> takePicture() async {
    if (!isInitialized) {
      _log.warning('Cannot take picture: camera not initialized');
      return null;
    }
    
    try {
      final XFile file = await _cameraController!.takePicture();
      _log.info('Picture taken: ${file.path}');
      return file.path;
    } catch (e) {
      _log.severe('Error taking picture: $e');
      return null;
    }
  }
  
  /// Dispose camera resources
  void dispose() {
    _cameraController?.dispose();
    _log.info('Camera service disposed');
  }
}

