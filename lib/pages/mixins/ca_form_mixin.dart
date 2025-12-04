import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';
import 'package:logging/logging.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

/// CA 表单生成 Mixin
/// 包含自动填充 CA3 表单的功能
mixin CaFormMixin<T extends StatefulWidget> on State<T> {
  // 需要子类提供
  Logger get logger;
  IdRecognitionResult? get ocrResult;
  
  // 需要子类实现的回调
  void onProcessingStateChange(bool isProcessing);
  void showSuccessMessage(String message);
  void showWarningMessage(String message);
  void showErrorMessage(String message);
  Future<bool> requestStoragePermission();
  
  // 需要子类实现姓名提取
  String extractNameFromDocument();

  /// 生成 CA 表单（自动填充姓名和证件号）
  Future<void> generateCaForm() async {
    // 验证是否已扫描文档
    if (ocrResult == null || !ocrResult!.hasIds) {
      showWarningMessage(
        'Please scan a document first!\n\n'
        '1. Click "Capture Document" or "Choose from Gallery"\n'
        '2. Scan HKID, China ID, or Passport\n'
        '3. Then click "Generate CA Form"'
      );
      return;
    }
    
    try {
      onProcessingStateChange(true);
      
      logger.info('Generating CA Form from scanned document...');
      
      // 步骤 1：提取姓名和证件号
      final extractedName = extractNameFromDocument();
      String extractedIdNo = '';
      String documentType = '';
      
      // 从解析结果中提取证件号
      for (final id in ocrResult!.parsedIds!) {
        documentType = id.type;
        
        if (id.type == 'HKID - Hong Kong ID Card') {
          extractedIdNo = id.fields['ID Number']?.toString() ?? '';
        } else if (id.type == 'China ID Card') {
          extractedIdNo = id.fields['ID Number']?.toString() ?? '';
        } else if (id.type == 'Passport') {
          extractedIdNo = id.fields['Passport No']?.toString() ?? '';
        }
        
        if (extractedIdNo.isNotEmpty) break;
      }
      
      logger.info('Extracted data - Name: "$extractedName", ID: "$extractedIdNo", Type: $documentType');
      
      // 验证至少有证件号
      if (extractedIdNo.isEmpty) {
        onProcessingStateChange(false);
        showErrorMessage('Failed to extract ID number from scanned document');
        return;
      }
      
      // 步骤 2：请求存储权限
      final hasPermission = await requestStoragePermission();
      
      // 步骤 3：加载 CA 3.pdf 模板
      final ByteData data = await rootBundle.load('assets/pdfs/CA 3.pdf');
      final pdfBytes = data.buffer.asUint8List();
      
      // 步骤 4：使用 Syncfusion PDF 填充字段
      final document = sf_pdf.PdfDocument(inputBytes: pdfBytes);
      final form = document.form;
      
      int filledCount = 0;
      
      if (form != null && form.fields.count > 0) {
        logger.info('Found ${form.fields.count} fields in CA 3.pdf');
        
        // 填充 Name 字段
        if (extractedName.isNotEmpty) {
          for (int i = 0; i < form.fields.count; i++) {
            final field = form.fields[i];
            if (field is sf_pdf.PdfTextBoxField && field.name == 'Name') {
              field.text = extractedName;
              filledCount++;
              logger.info('Filled Name field: $extractedName');
              break;
            }
          }
        }
        
        // 填充 IdNo 字段
        for (int i = 0; i < form.fields.count; i++) {
          final field = form.fields[i];
          if (field is sf_pdf.PdfTextBoxField && field.name == 'IdNo') {
            field.text = extractedIdNo;
            filledCount++;
            logger.info('Filled IdNo field: $extractedIdNo');
            break;
          }
        }
      }
      
      logger.info('Successfully filled $filledCount fields');
      
      // 步骤 5：保存填充后的 PDF
      final finalBytes = await document.save();
      document.dispose();
      
      // 步骤 6：保存到 Downloads 文件夹
      Directory? saveDir;
      String locationMsg = '';
      
      if (Platform.isAndroid && hasPermission) {
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          try {
            await saveDir.create(recursive: true);
            locationMsg = '📂 Saved to Downloads folder';
          } catch (e) {
            saveDir = await getTemporaryDirectory();
            locationMsg = '📂 Saved to app storage';
          }
        } else {
          locationMsg = '📂 Saved to Downloads folder';
        }
      } else {
        saveDir = await getTemporaryDirectory();
        locationMsg = '📂 Saved to app storage';
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'CA3_FILLED_$timestamp.pdf';
      final caFormFile = File('${saveDir!.path}/$fileName');
      await caFormFile.writeAsBytes(finalBytes);
      
      onProcessingStateChange(false);
      
      // 步骤 7：打开填充后的 PDF
      await OpenFile.open(caFormFile.path);
      
      // 步骤 8：显示成功消息
      String message = '✅ CA Form 已生成！\n\n';
      message += '📋 已填充信息:\n';
      if (extractedName.isNotEmpty) {
        message += '• 姓名: $extractedName\n';
      } else {
        message += '• 姓名: (未找到，請手動填寫)\n';
      }
      message += '• 證件號碼: $extractedIdNo\n';
      message += '• 證件類型: $documentType\n\n';
      message += '$locationMsg\n';
      message += '文件名: $fileName';
      
      showSuccessMessage(message);
      
      logger.info('CA Form saved: ${caFormFile.path}');
      
    } catch (e) {
      onProcessingStateChange(false);
      logger.severe('Failed to generate CA Form', e);
      showErrorMessage('CA Form 生成失敗: $e');
    }
  }
}


