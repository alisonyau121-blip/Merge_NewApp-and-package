import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';
import 'package:logging/logging.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

/// PDF 签名处理 Mixin
/// 包含数字签名、PDF 生成、预览、下载等功能
mixin PdfSignatureMixin<T extends StatefulWidget> on State<T> {
  // 需要子类提供
  Logger get logger;
  File? get generatedPdf;
  File? get signedPdf;
  SignatureResult? get signatureData;
  Map<String, String>? get savedFormData;
  
  // 需要子类实现的回调
  void onProcessingStateChange(bool isProcessing);
  void onSignatureUpdate(SignatureResult signatureResult, String filename);
  void onPdfGenerated(File pdfFile);
  void showSuccessMessage(String message);
  void showWarningMessage(String message);
  void showErrorMessage(String message);
  void showInfoDialogCallback(String title, String content);
  Future<bool> requestStoragePermission();

  /// 应用数字签名
  Future<void> applyDigitalSignature() async {
    try {
      onProcessingStateChange(true);

      // 1. 创建签名控制器
      final signatureController = SignatureController(
        penStrokeWidth: 3,
        penColor: Colors.black,
        exportBackgroundColor: Colors.white,
      );

      // 2. 显示签名捕获对话框
      final signed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.draw, color: Colors.purple),
              const SizedBox(width: 8),
              const Text('Draw Your Signature'),
            ],
          ),
          content: Container(
            width: 400,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Signature(
                    controller: signatureController,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign here with your finger or stylus',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                signatureController.clear();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
            TextButton(
              onPressed: () {
                signatureController.dispose();
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (signatureController.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please draw your signature first')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.check),
              label: const Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

      if (signed != true) {
        signatureController.dispose();
        onProcessingStateChange(false);
        return;
      }

      // 3. 将签名转换为 PNG 字节
      final signatureBytes = await signatureController.toPngBytes();
      signatureController.dispose();
      
      if (signatureBytes == null) {
        throw Exception('Failed to capture signature image');
      }

      // 4. 使用 id_ocr_kit 模型创建 SignatureResult
      final timestamp = DateTime.now();
      final signatureResult = SignatureResult(
        previewPng: signatureBytes,
        transparentPng: signatureBytes,
        timestamp: timestamp,
        role: 'Client',
      );

      onSignatureUpdate(signatureResult, signatureResult.defaultFilename);
      onProcessingStateChange(false);

      showSuccessMessage(
        'Digital signature captured!\n'
        'Role: ${signatureResult.role}\n'
        'Time: ${signatureResult.timestamp.toString().substring(0, 19)}'
      );
    } catch (e) {
      onProcessingStateChange(false);
      showErrorMessage('Signature failed: $e');
    }
  }

  /// 预览签名 PDF
  Future<void> previewSignedPdf() async {
    if (generatedPdf == null) {
      showInfoDialogCallback(
        'No PDF Available',
        'Please generate a PDF first by:\n\n1. Capture or choose a document\n2. Click "Generate Signed PDF"',
      );
      return;
    }

    try {
      onProcessingStateChange(true);
      await OpenFile.open(generatedPdf!.path);
      onProcessingStateChange(false);
      showSuccessMessage('Opening PDF...');
    } catch (e) {
      onProcessingStateChange(false);
      showErrorMessage('Preview failed: $e');
    }
  }

  /// 下载签名 PDF
  Future<void> downloadSignedPdf() async {
    if (signedPdf == null && generatedPdf == null) {
      showInfoDialogCallback(
        'No PDF to Download',
        'Please follow these steps:\n\n1. Capture a document\n2. Apply digital signature (optional)\n3. Generate signed PDF\n\nThen try downloading again.',
      );
      return;
    }

    try {
      onProcessingStateChange(true);
      await Future.delayed(const Duration(milliseconds: 500));
      
      final pdfPath = signedPdf?.path ?? generatedPdf?.path ?? '';
      onProcessingStateChange(false);
      showSuccessMessage('PDF saved to:\n$pdfPath');
    } catch (e) {
      onProcessingStateChange(false);
      showErrorMessage('Download failed: $e');
    }
  }

  /// 生成签名 PDF（插入签名和表单数据到 MINA PDF 模板）
  Future<void> generateSignedPdf() async {
    try {
      onProcessingStateChange(true);

      // 步骤 0：请求存储权限
      final hasPermission = await requestStoragePermission();
      
      // 步骤 1：加载 MINA PDF 模板
      final ByteData data = await rootBundle.load('assets/pdfs/MINA (3).pdf');
      final pdfBytes = data.buffer.asUint8List();
      
      // 步骤 2：创建 Syncfusion PDF 适配器
      final pdfAdapter = SyncfusionPdfAdapter();
      
      // 步骤 3：加载 PDF 文档
      final pdfDoc = await pdfAdapter.loadPdf(pdfBytes);
      
      // 步骤 4：填充表单字段（如果有表单数据）
      if (savedFormData != null && savedFormData!.isNotEmpty) {
        logger.info('Filling PDF with saved form data...');
        int filledCount = 0;
        
        for (final entry in savedFormData!.entries) {
          if (entry.value.isNotEmpty) {
            try {
              await pdfAdapter.fillTextField(
                document: pdfDoc,
                fieldName: entry.key,
                value: entry.value,
              );
              filledCount++;
              logger.fine('Filled field: ${entry.key} = ${entry.value}');
            } catch (e) {
              logger.warning('Field "${entry.key}" not found or failed: $e');
            }
          }
        }
        
        logger.info('Successfully filled $filledCount fields');
      }
      
      // 步骤 5：在 ClientSign 字段插入签名
      if (signatureData != null) {
        try {
          await pdfAdapter.insertSignatureAtFormField(
            document: pdfDoc,
            fieldName: 'ClientSign',
            signatureBytes: signatureData!.transparentPng,
          );
          
          logger.info('Signature successfully inserted at ClientSign field');
        } catch (e) {
          logger.severe('Failed to insert signature at ClientSign field', e);
          showWarningMessage('簽名插入失敗，但表單數據已填充');
        }
      }
      
      // 步骤 6：保存 PDF
      final finalPdfBytes = await pdfAdapter.savePdf(pdfDoc);
      await pdfAdapter.dispose(pdfDoc);
      
      // 步骤 7：保存到设备 Downloads 文件夹
      Directory? saveDir;
      String locationMsg = '';
      
      if (Platform.isAndroid && hasPermission) {
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          try {
            await saveDir.create(recursive: true);
            locationMsg = '📂 Saved to Downloads folder';
          } catch (e) {
            saveDir = await getExternalStorageDirectory();
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
      final pdfFile = File('${saveDir!.path}/complete_mina_$timestamp.pdf');
      await pdfFile.writeAsBytes(finalPdfBytes);

      onPdfGenerated(pdfFile);
      onProcessingStateChange(false);

      // 构建成功消息
      String message = 'MINA PDF 生成成功！\n';
      if (savedFormData != null) {
        message += '✅ 表單信息已填充\n';
      }
      if (signatureData != null) {
        message += '✅ 客戶簽名已插入\n';
      }
      message += '\n$locationMsg\n';
      message += 'Filename: complete_mina_$timestamp.pdf';
      
      showSuccessMessage(message);
    } catch (e) {
      onProcessingStateChange(false);
      showErrorMessage('PDF generation failed: $e');
    }
  }

  /// 创建标记 PDF（每个字段显示其内部名称）
  Future<void> createLabeledPdf(String selectedPdfToInspect) async {
    try {
      onProcessingStateChange(true);
      
      logger.info('Creating labeled PDF for $selectedPdfToInspect...');
      
      // 加载选定的 PDF
      final ByteData data = await rootBundle.load('assets/pdfs/$selectedPdfToInspect');
      final pdfBytes = data.buffer.asUint8List();
      
      // 直接使用 Syncfusion PDF
      final document = sf_pdf.PdfDocument(inputBytes: pdfBytes);
      final form = document.form;
      
      int labeledCount = 0;
      
      if (form != null && form.fields.count > 0) {
        logger.info('Found ${form.fields.count} fields to label');
        
        for (int i = 0; i < form.fields.count; i++) {
          final field = form.fields[i];
          
          // 填充文本字段
          if (field is sf_pdf.PdfTextBoxField && field.name != null) {
            field.text = field.name!;
            labeledCount++;
            logger.fine('Labeled field ${i + 1}: ${field.name}');
          }
          // 复选框只记录日志
          else if (field is sf_pdf.PdfCheckBoxField && field.name != null) {
            logger.fine('CheckBox field ${i + 1}: ${field.name} (cannot label checkbox)');
          }
        }
      }
      
      logger.info('Successfully labeled $labeledCount text fields');
      
      // 保存标记后的 PDF
      final finalBytes = await document.save();
      document.dispose();
      
      // 保存到 Downloads/temp 文件夹
      Directory? saveDir;
      String locationMsg = '';
      
      if (Platform.isAndroid) {
        final hasPermission = await requestStoragePermission();
        if (hasPermission) {
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
      } else {
        saveDir = await getTemporaryDirectory();
        locationMsg = '📂 Saved to app storage';
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = selectedPdfToInspect.replaceAll('.pdf', '_LABELED_$timestamp.pdf');
      final labeledFile = File('${saveDir!.path}/$fileName');
      await labeledFile.writeAsBytes(finalBytes);
      
      onProcessingStateChange(false);
      
      // 打开标记后的 PDF
      await OpenFile.open(labeledFile.path);
      
      showSuccessMessage(
        '✅ 標記 PDF 已創建！\n'
        '已標記 $labeledCount 個文本字段\n'
        '每個字段現在顯示其內部名稱\n\n'
        '$locationMsg\n'
        '文件名: $fileName\n\n'
        '💡 現在你可以看到哪個內部名稱對應哪個可見欄位了！'
      );
      
      logger.info('Labeled PDF saved: ${labeledFile.path}');
    } catch (e) {
      onProcessingStateChange(false);
      logger.severe('Failed to create labeled PDF', e);
      showErrorMessage('創建標記 PDF 失敗: $e');
    }
  }
}

