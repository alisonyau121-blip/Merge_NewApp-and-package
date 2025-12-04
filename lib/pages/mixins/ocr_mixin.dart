import 'dart:io';
import 'package:flutter/material.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

/// OCR 功能 Mixin
/// 包含文档扫描、OCR 识别等相关功能
mixin OcrMixin<T extends StatefulWidget> on State<T> {
  // 需要子类提供
  Logger get logger;
  IdRecognitionService get idService;
  
  // 需要子类实现的回调
  void onOcrResultUpdate(IdRecognitionResult result, File? capturedImage);
  void onProcessingStateChange(bool isProcessing);
  void showSuccessMessage(String message);
  void showWarningMessage(String message);
  void showErrorMessage(String message);

  /// 从相机捕获文档
  Future<void> captureDocument() async {
    await scanDocument(ImageSource.camera);
  }

  /// 从相册选择文档
  Future<void> chooseFromGallery() async {
    await scanDocument(ImageSource.gallery);
  }

  /// 主扫描功能（使用 id_ocr_kit）
  Future<void> scanDocument(ImageSource source) async {
    try {
      onProcessingStateChange(true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image == null) {
        onProcessingStateChange(false);
        return;
      }

      final imageFile = File(image.path);

      // 使用 id_ocr_kit 识别身份证
      final result = await idService.recognizeId(imageFile);

      // 更新结果
      onOcrResultUpdate(result, imageFile);
      onProcessingStateChange(false);

      if (result.isSuccess && result.hasIds) {
        showSuccessMessage('Document recognized successfully! Check scan results below.');
      } else {
        showWarningMessage('No ID found in the image');
      }
    } catch (e) {
      onProcessingStateChange(false);
      showErrorMessage('Error: $e');
    }
  }

  /// 请求存储权限（用于保存 PDF）
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true; // 非 Android 平台无需权限
    }

    // Android 13+ (API 33+) 不需要 WRITE_EXTERNAL_STORAGE 权限
    if (Platform.isAndroid) {
      final androidVersion = await getAndroidVersion();
      if (androidVersion >= 33) {
        return true;
      }
    }

    // Android 11-12，检查是否已有权限
    var status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }

    // 请求权限
    status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    }

    // 权限被拒绝
    if (status.isPermanentlyDenied) {
      showErrorMessage(
        'Storage permission is required to save PDFs.\n'
        'Please enable it in app settings.',
      );
      await openAppSettings();
    } else {
      showWarningMessage('Storage permission denied. PDF will be saved to app folder.');
    }

    return false;
  }

  /// 获取 Android 版本
  Future<int> getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    // 简化处理，假设现代模拟器都是 Android 13+
    // 生产环境应使用 device_info_plus 包获取准确版本
    return 33;
  }
}


