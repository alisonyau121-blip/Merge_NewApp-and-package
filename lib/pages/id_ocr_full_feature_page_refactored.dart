import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';
import 'package:logging/logging.dart';
import '../utils/pdf_field_inspector.dart';
import 'form_fill_page.dart';
import 'mixins/ocr_mixin.dart';
import 'mixins/name_extraction_mixin.dart';
import 'mixins/ca_form_mixin.dart';
import 'mixins/pdf_signature_mixin.dart';
import 'mixins/ui_helpers_mixin.dart';

/// ID OCR 完整功能页面
/// 
/// 功能模块化结构：
/// - OcrMixin: 文档扫描和 OCR 识别
/// - NameExtractionMixin: 姓名提取逻辑
/// - CaFormMixin: CA 表单自动填充
/// - PdfSignatureMixin: PDF 签名处理
/// - UiHelpersMixin: UI 辅助方法
class IdOcrFullFeaturePage extends StatefulWidget {
  const IdOcrFullFeaturePage({super.key});

  @override
  State<IdOcrFullFeaturePage> createState() => _IdOcrFullFeaturePageState();
}

class _IdOcrFullFeaturePageState extends State<IdOcrFullFeaturePage>
    with
        OcrMixin,
        NameExtractionMixin,
        CaFormMixin,
        PdfSignatureMixin,
        UiHelpersMixin {
  
  // ============================================
  // 状态变量
  // ============================================
  
  static final _log = Logger('IdOcrFullFeaturePage');
  
  // OCR 相关
  IdRecognitionResult? _result;
  File? _capturedImage;
  bool _showRawText = false;
  
  // PDF 相关
  File? _generatedPdf;
  File? _signedPdf;
  String _selectedPdfToInspect = 'MINA (3).pdf';
  
  // 签名相关
  String? _digitalSignature;
  SignatureResult? _signatureData;
  
  // 表单数据
  Map<String, String>? _savedFormData;
  
  // 处理状态
  bool _isProcessing = false;

  // 服务
  late final IdRecognitionService _idService;
  late final PdfFormService _pdfFormService;

  // ============================================
  // 生命周期方法
  // ============================================
  
  @override
  void initState() {
    super.initState();
    _idService = IdRecognitionService(
      ocrProvider: MlKitOcrAdapter(),
    );
    _pdfFormService = PdfFormService(
      pdfProvider: SyncfusionPdfAdapter(),
    );
  }

  @override
  void dispose() {
    _idService.dispose();
    super.dispose();
  }

  // ============================================
  // Mixin 接口实现 - OcrMixin
  // ============================================
  
  @override
  Logger get logger => _log;

  @override
  IdRecognitionService get idService => _idService;

  @override
  void onOcrResultUpdate(IdRecognitionResult result, File? capturedImage) {
    setState(() {
      _result = result;
      _capturedImage = capturedImage;
      _showRawText = (result.isSuccess && result.hasIds);
      // 重置 PDF 状态
      _digitalSignature = null;
      _generatedPdf = null;
      _signedPdf = null;
    });
  }

  @override
  void onProcessingStateChange(bool isProcessing) {
    setState(() => _isProcessing = isProcessing);
  }

  @override
  void showSuccessMessage(String message) => showSuccessSnackBar(message);

  @override
  void showWarningMessage(String message) => showWarningSnackBar(message);

  @override
  void showErrorMessage(String message) => showErrorSnackBar(message);

  // ============================================
  // Mixin 接口实现 - NameExtractionMixin
  // ============================================
  
  @override
  IdRecognitionResult? get ocrResult => _result;

  // ============================================
  // Mixin 接口实现 - PdfSignatureMixin
  // ============================================
  
  @override
  File? get generatedPdf => _generatedPdf;

  @override
  File? get signedPdf => _signedPdf;

  @override
  SignatureResult? get signatureData => _signatureData;

  @override
  Map<String, String>? get savedFormData => _savedFormData;

  @override
  void onSignatureUpdate(SignatureResult signatureResult, String filename) {
    setState(() {
      _signatureData = signatureResult;
      _digitalSignature = filename;
    });
  }

  @override
  void onPdfGenerated(File pdfFile) {
    setState(() {
      _generatedPdf = pdfFile;
      _signedPdf = pdfFile;
    });
  }

  @override
  void showInfoDialogCallback(String title, String content) {
    showInfoDialog(title, content);
  }

  // ============================================
  // 其他页面特定方法
  // ============================================
  
  /// 打开表单填充页面
  Future<void> _openFormFillPage() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => FormFillPage(
          existingFormData: _savedFormData,
          existingSignature: _signatureData,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _savedFormData = result;
      });
      showSuccessSnackBar('表單信息已保存！\n點擊 "Generate Signed PDF" 生成完整的PDF');
    }
  }

  // ============================================
  // UI 构建方法
  // ============================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        title: const Text('ID OCR Demo'),
        elevation: 0,
        actions: [
          if (_generatedPdf != null)
            IconButton(
              icon: const Icon(Icons.folder),
              onPressed: () {
                showInfoDialog(
                  'Generated Files',
                  'PDF: ${_generatedPdf?.path ?? 'None'}\n\n'
                  'Signed PDF: ${_signedPdf?.path ?? 'None'}',
                );
              },
              tooltip: 'View saved files',
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 标题部分
                _buildHeader(),
                const SizedBox(height: 20),
                
                // 提示信息
                if (_result == null) _buildInfoHint(),
                const SizedBox(height: 20),

                // 功能按钮组
                _buildActionButtons(),
                const SizedBox(height: 12),

                // PDF 检查器
                _buildPdfInspector(),
                const SizedBox(height: 12),

                // 其他功能按钮
                _buildOtherButtons(),
                const SizedBox(height: 20),

                // 捕获的图像预览
                if (_capturedImage != null) ...[
                  _buildCapturedImagePreview(),
                  const SizedBox(height: 12),
                ],

                // 原始扫描文本
                if (_result != null && _result!.rawText != null) ...[
                  _buildRawTextCard(),
                  const SizedBox(height: 12),
                ],

                // 解析结果卡片
                if (_result != null) _buildParsedResultsCard(),
                
                // 表单数据状态卡片
                if (_savedFormData != null) ...[
                  const SizedBox(height: 12),
                  _buildFormDataCard(),
                ],
              ],
            ),
          ),

          // 加载覆盖层
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.document_scanner,
            size: 60,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ID OCR Recognition',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Scan Hong Kong ID, China ID, or Passport',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 构建提示信息
  Widget _buildInfoHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.info, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '👆 Please scan a document first to enable other features',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Column(
      children: [
        // 捕获文档按钮（蓝色）
        buildFeatureButton(
          label: 'Capture Document',
          icon: Icons.camera_alt,
          color: Colors.blue,
          onPressed: captureDocument,
          isProcessing: _isProcessing,
        ),
        const SizedBox(height: 12),

        // 从相册选择按钮（绿色）
        buildFeatureButton(
          label: 'Choose from Gallery',
          icon: Icons.photo_library,
          color: Colors.green,
          onPressed: chooseFromGallery,
          isProcessing: _isProcessing,
        ),
        const SizedBox(height: 12),

        // 生成 CA 表单按钮（粉色）
        buildFeatureButton(
          label: 'Generate CA Form',
          icon: Icons.description,
          color: Colors.pink,
          onPressed: generateCaForm,
          isProcessing: _isProcessing,
        ),
      ],
    );
  }

  /// 构建 PDF 检查器
  Widget _buildPdfInspector() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bug_report, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text(
                  'PDF Inspector (Debug)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedPdfToInspect,
              decoration: InputDecoration(
                labelText: 'Select PDF to Inspect',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(
                  value: 'MINA (3).pdf',
                  child: Text('MINA PDF'),
                ),
                DropdownMenuItem(
                  value: 'CA 3.pdf',
                  child: Text('CA3 PDF'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPdfToInspect = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final details = await PdfFieldInspector.getFormFieldDetails(
                    'assets/pdfs/$_selectedPdfToInspect',
                  );
                  
                  final buffer = StringBuffer();
                  buffer.writeln('Found ${details.length} fields:\n');
                  
                  final pageGroups = <int, List<Map<String, dynamic>>>{};
                  for (final field in details) {
                    final page = field['page'] as int;
                    pageGroups.putIfAbsent(page, () => []).add(field);
                  }
                  
                  for (final page in pageGroups.keys.toList()..sort()) {
                    buffer.writeln('📄 PAGE $page:');
                    
                    final pageFields = pageGroups[page]!;
                    pageFields.sort((a, b) => (a['top'] as int).compareTo(b['top'] as int));
                    
                    for (final field in pageFields) {
                      buffer.writeln('  ${field['index']}. ${field['name']}');
                      buffer.writeln('     Position: (${field['left']}, ${field['top']})');
                    }
                    buffer.writeln();
                  }
                  
                  buffer.writeln('💡 Check console for complete details with coordinates!');
                  
                  showInfoDialog(
                    'PDF Form Fields - $_selectedPdfToInspect',
                    buffer.toString(),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Inspect Form Fields'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => createLabeledPdf(_selectedPdfToInspect),
                icon: const Icon(Icons.label),
                label: const Text('Visualize PDF Fields'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '💡 Creates a PDF where each field shows its internal name',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建其他按钮
  Widget _buildOtherButtons() {
    return Column(
      children: [
        // 数字签名按钮（紫色）
        buildFeatureButton(
          label: _digitalSignature != null
              ? 'Digital Signature ✓'
              : 'Digital Signature',
          icon: _digitalSignature != null ? Icons.verified : Icons.edit,
          color: _digitalSignature != null ? Colors.deepPurple : Colors.purple,
          onPressed: applyDigitalSignature,
          isProcessing: _isProcessing,
        ),
        const SizedBox(height: 12),

        // 预览签名 PDF 按钮（橙色）
        buildFeatureButton(
          label: 'Preview Signed PDF',
          icon: Icons.picture_as_pdf,
          color: Colors.orange,
          onPressed: previewSignedPdf,
          isProcessing: _isProcessing,
        ),
        const SizedBox(height: 12),

        // 下载签名 PDF 按钮（青色）
        buildFeatureButton(
          label: 'Download Signed PDF',
          icon: Icons.download,
          color: Colors.teal,
          onPressed: downloadSignedPdf,
          isProcessing: _isProcessing,
        ),
        const SizedBox(height: 12),

        // 生成签名 PDF 按钮（靛蓝）
        buildFeatureButton(
          label: _generatedPdf != null
              ? 'Generate Signed PDF ✓'
              : 'Generate Signed PDF',
          icon: _generatedPdf != null
              ? Icons.check_circle
              : Icons.picture_as_pdf_outlined,
          color: Colors.indigo,
          onPressed: generateSignedPdf,
          isProcessing: _isProcessing,
        ),
        const SizedBox(height: 12),

        // 填写个人信息表单按钮（绿色）
        buildFeatureButton(
          label: _savedFormData != null
              ? 'Fill Personal Information Form ✓'
              : 'Fill Personal Information Form',
          icon: _savedFormData != null ? Icons.assignment_turned_in : Icons.assignment,
          color: _savedFormData != null ? Colors.green[700]! : Colors.green,
          onPressed: _openFormFillPage,
          isProcessing: _isProcessing,
        ),
      ],
    );
  }

  /// 构建捕获的图像预览
  Widget _buildCapturedImagePreview() {
    return Card(
      color: Colors.grey[850],
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[800],
            child: const Row(
              children: [
                Icon(Icons.image, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Captured Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Image.file(
            _capturedImage!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  /// 构建原始文本卡片
  Widget _buildRawTextCard() {
    return Card(
      color: Colors.grey[850],
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showRawText = !_showRawText;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.2),
                    Colors.grey[850]!,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.document_scanner,
                    color: Colors.orange,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scanned Text from ID Card',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_result!.lines?.length ?? 0} lines detected',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showRawText
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.orange,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (_showRawText)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                border: Border(
                  top: BorderSide(color: Colors.orange.withOpacity(0.3), width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Raw OCR Output (Latin script only):',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: SelectableText(
                      _result!.rawText!.isEmpty
                          ? '(No text detected)'
                          : _result!.rawText!,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 14,
                        fontFamily: 'Courier New',
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.copy,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tip: Long press text to copy',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建解析结果卡片
  Widget _buildParsedResultsCard() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _result!.hasIds
                      ? Icons.check_circle
                      : Icons.warning,
                  color: _result!.hasIds
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _result!.hasIds
                      ? 'Document Recognized (${_result!.idCount} found)'
                      : 'No Document Found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_result!.hasIds) ...[
              const Divider(color: Colors.grey, height: 24),
              for (var id in _result!.parsedIds!)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id.type,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var entry in id.fields.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                entry.value.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
            ],
            
            // 数字签名状态
            if (_digitalSignature != null) ...[
              const Divider(color: Colors.grey, height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.purple, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Digital Signature Applied',
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_signatureData != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Role: ${_signatureData!.role} • ${_signatureData!.timestamp.toString().substring(0, 16)}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  // 签名预览
                  if (_signatureData != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 120,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Image.memory(
                              _signatureData!.previewPng,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Signature Preview',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ready for PDF insertion',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
            
            // PDF 生成状态
            if (_generatedPdf != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.indigo, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'PDF Generated',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // 处理时间
            if (_result!.processingTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Processing Time: ${_result!.processingTime!.inMilliseconds}ms',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建表单数据卡片
  Widget _buildFormDataCard() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Form Data Saved',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildInfoRow('Name', _savedFormData!['FullName'] ?? '-'),
                  if (_savedFormData!['FullNameLoc']?.isNotEmpty == true)
                    buildInfoRow('中文名稱', _savedFormData!['FullNameLoc']!),
                  buildInfoRow('Gender', _savedFormData!['Gender'] ?? '-'),
                  buildInfoRow('Nationality', _savedFormData!['Nationality'] ?? '-'),
                  if (_savedFormData!['CompanyName']?.isNotEmpty == true)
                    buildInfoRow('Company', _savedFormData!['CompanyName']!),
                  const SizedBox(height: 8),
                  Text(
                    '✓ ${_savedFormData!.length} fields ready for PDF',
                    style: TextStyle(
                      color: Colors.green[300],
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载覆盖层
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Processing...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


