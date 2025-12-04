import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';
import 'package:logging/logging.dart';
import '../services/camera_service.dart';
import 'scan_result_page.dart';

/// ID Scanner Screen - Real-time camera preview with OCR
/// Design based on ID Scanner UI Recreation (1:1 replica)
/// Part of Test Figma feature, independent from Scan ID page
class IdScannerScreen extends StatefulWidget {
  const IdScannerScreen({super.key});

  @override
  State<IdScannerScreen> createState() => _IdScannerScreenState();
}

class _IdScannerScreenState extends State<IdScannerScreen> {
  static final _log = Logger('IdScannerScreen');
  
  final CameraService _cameraService = CameraService();
  late final IdRecognitionService _idService;
  
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _idService = IdRecognitionService(
      ocrProvider: MlKitOcrAdapter(),
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _idService.dispose();
    super.dispose();
  }

  /// Take picture and perform OCR recognition
  Future<void> _takePictureAndRecognize() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Take picture
      final imagePath = await _cameraService.takePicture();
      if (imagePath == null) {
        _showError('Failed to capture image');
        return;
      }

      _log.info('Image captured: $imagePath');

      // Perform OCR recognition
      final imageFile = File(imagePath);
      final result = await _idService.recognizeId(imageFile);

      if (!mounted) return;

      // Navigate to result page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanResultPage(result: result),
        ),
      );
    } catch (e) {
      _log.severe('Error during capture and OCR: $e');
      _showError('Recognition failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan ID'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3F5AA6), // Original design color
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Camera preview or loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.amber,
              ),
            )
          else if (!_cameraService.isInitialized)
            const Center(
              child: Text(
                'Camera not available',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            // Real-time camera preview (full screen)
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(_cameraService.controller!),
            ),

          // ID scanning overlay (based on original design)
          Column(
            children: [
              const SizedBox(height: 20),
              
              // "Front of ID" text with close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Front of ID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // ID icon with yellow border
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.contact_mail,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Main scanning area with yellow border
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.width * 0.5,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              
              const Spacer(),
              
              // Bottom navigation bar (decorative, as per requirement)
              Container(
                height: 60,
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, isSelected: false),
                    _buildNavItem(Icons.description, isSelected: true),
                    _buildNavItem(Icons.photo_library, isSelected: false),
                    _buildNavItem(Icons.people, isSelected: false),
                    _buildNavItem(Icons.label, isSelected: false),
                    _buildNavItem(Icons.emoji_events, isSelected: false),
                  ],
                ),
              ),
            ],
          ),
          
          // Sign in button and QR code at the bottom (from original design)
          // We'll use these as the trigger for taking picture
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // "Sign In" button - triggers photo capture and OCR
                ElevatedButton(
                  onPressed: _isProcessing ? null : _takePictureAndRecognize,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 40),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Capture'),
                ),
                const SizedBox(width: 20),
                // QR button (decorative as per original design)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.amber,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Recognizing ID...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build navigation item (decorative only)
  Widget _buildNavItem(IconData icon, {required bool isSelected}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey,
        ),
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

