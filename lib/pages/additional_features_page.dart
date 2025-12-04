import 'dart:io';
import 'package:flutter/material.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';
import 'package:logging/logging.dart';
import '../utils/pdf_field_inspector.dart';
import 'form_fill_page.dart';
import 'mixins/name_extraction_mixin.dart';
import 'mixins/ca_form_mixin.dart';
import 'mixins/pdf_signature_mixin.dart';
import 'mixins/ui_helpers_mixin.dart';

/// Additional Features 页面
/// 
/// 包含所有额外功能：
/// - CA Form Generation
/// - Digital Signature
/// - PDF Operations
/// - Form Filling
/// - PDF Inspector
class AdditionalFeaturesPage extends StatefulWidget {
  /// 初始扫描结果（可选，从 Scan ID 页面传递过来）
  final IdRecognitionResult? initialResult;
  
  const AdditionalFeaturesPage({
    super.key,
    this.initialResult,
  });

  @override
  State<AdditionalFeaturesPage> createState() => _AdditionalFeaturesPageState();
}

class _AdditionalFeaturesPageState extends State<AdditionalFeaturesPage>
    with
        NameExtractionMixin,
        CaFormMixin,
        PdfSignatureMixin,
        UiHelpersMixin {
  
  // ============================================
  // 状态变量
  // ============================================
  
  static final _log = Logger('AdditionalFeaturesPage');
  
  // OCR 相关（用于 CA Form 和 Name Extraction）
  IdRecognitionResult? _result;
  
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
    
    // Create AI parser service for enhanced field extraction
    final aiService = AiParserService(
      //apiUrl: 'https://amg-backend-dev-api3.azurewebsites.net/api/chat',
      apiUrl: 'http://10.0.2.2:8006/api/chat',  // Android emulator localhost alias
      apiKey: '3razU1sHTAPGdCL5tKSMpOIbkxgJ9E6j',
    );
    
    // Initialize ID service with AI enhancement
    _idService = IdRecognitionService(
      ocrProvider: MlKitOcrAdapter(),
      aiParserService: aiService,
    );
    _pdfFormService = PdfFormService(
      pdfProvider: SyncfusionPdfAdapter(),
    );
    
    // 如果有初始扫描结果，使用它
    if (widget.initialResult != null) {
      _result = widget.initialResult;
      _log.info('✅ Loaded scan result from previous page: ${_result?.idCount} IDs found');
    }
  }

  @override
  void dispose() {
    _idService.dispose();
    super.dispose();
  }

  // ============================================
  // Mixin 接口实现 - NameExtractionMixin
  // ============================================
  
  @override
  Logger get logger => _log;

  @override
  IdRecognitionResult? get ocrResult => _result;

  // ============================================
  // Mixin 接口实现 - CaFormMixin
  // ============================================
  
  @override
  bool get isProcessing => _isProcessing;

  @override
  set isProcessing(bool value) => setState(() => _isProcessing = value);

  @override
  void showWarningSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void showSuccessMessage(String message) => showSuccessSnackBar(message);

  @override
  void showWarningMessage(String message) => showWarningSnackBar(message);

  @override
  void showErrorMessage(String message) => showErrorSnackBar(message);

  @override
  void onProcessingStateChange(bool value) {
    setState(() => _isProcessing = value);
  }

  @override
  Future<bool> requestStoragePermission() async {
    // For now, return true. You can implement proper permission handling later
    return true;
  }

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

  @override
  String get selectedPdfToInspect => _selectedPdfToInspect;

  @override
  PdfFormService get pdfFormService => _pdfFormService;

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
      backgroundColor: const Color(0xff1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xff4a5f8c),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Additional Features',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_generatedPdf != null)
            IconButton(
              icon: const Icon(Icons.folder, color: Colors.white),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 页面说明
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff2a2a2a),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffffb800).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: const Color(0xffffb800), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Manage documents, signatures, and PDF operations',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Document Processing Section
                _buildSectionHeader('📋 Document Processing'),
                const SizedBox(height: 12),
                
                // Generate CA Form button
                _buildFeatureButton(
                  label: 'Generate CA Form',
                  icon: Icons.description,
                  color: Colors.pink,
                  onPressed: generateCaForm,
                ),
                const SizedBox(height: 12),
                
                // Fill Personal Info button
                _buildFeatureButton(
                  label: _savedFormData != null
                      ? 'Fill Personal Information ✓'
                      : 'Fill Personal Information',
                  icon: _savedFormData != null ? Icons.assignment_turned_in : Icons.assignment,
                  color: _savedFormData != null ? Colors.green[700]! : Colors.green,
                  onPressed: _openFormFillPage,
                ),
                const SizedBox(height: 24),

                // PDF Operations Section
                _buildSectionHeader('✍️ PDF Operations'),
                const SizedBox(height: 12),
                
                // Digital Signature button
                _buildFeatureButton(
                  label: _digitalSignature != null
                      ? 'Digital Signature ✓'
                      : 'Digital Signature',
                  icon: _digitalSignature != null ? Icons.verified : Icons.edit,
                  color: _digitalSignature != null ? Colors.deepPurple : Colors.purple,
                  onPressed: applyDigitalSignature,
                ),
                const SizedBox(height: 12),
                
                // Generate Signed PDF button
                _buildFeatureButton(
                  label: _generatedPdf != null
                      ? 'Generate Signed PDF ✓'
                      : 'Generate Signed PDF',
                  icon: _generatedPdf != null
                      ? Icons.check_circle
                      : Icons.picture_as_pdf_outlined,
                  color: Colors.indigo,
                  onPressed: generateSignedPdf,
                ),
                const SizedBox(height: 12),
                
                // Preview PDF button
                _buildFeatureButton(
                  label: 'Preview Signed PDF',
                  icon: Icons.picture_as_pdf,
                  color: Colors.orange,
                  onPressed: previewSignedPdf,
                ),
                const SizedBox(height: 12),
                
                // Download PDF button
                _buildFeatureButton(
                  label: 'Download Signed PDF',
                  icon: Icons.download,
                  color: Colors.teal,
                  onPressed: downloadSignedPdf,
                ),
                const SizedBox(height: 24),

                // Developer Tools Section
                _buildSectionHeader('🛠️ Developer Tools'),
                const SizedBox(height: 12),
                _buildPdfInspector(),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // 加载覆盖层
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xffffb800),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建功能按钮
  Widget _buildFeatureButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// 构建 PDF 检查器
  Widget _buildPdfInspector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff2a2a2a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff4a5f8c).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, color: Color(0xffffb800), size: 20),
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
    );
  }

  /// 构建加载覆盖层
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xffffb800),
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

