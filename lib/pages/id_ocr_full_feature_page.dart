import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';
import 'package:logging/logging.dart';
import 'additional_features_page.dart';
import 'mixins/ocr_mixin.dart';
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
        UiHelpersMixin {
  
  // ============================================
  // 状态变量
  // ============================================
  
  static final _log = Logger('IdOcrFullFeaturePage');
  
  // OCR 相关
  IdRecognitionResult? _result;
  File? _capturedImage;
  bool _showRawText = false;
  
  // PDF 相关 (removed - moved to AdditionalFeaturesPage)
  // Signature 相关 (removed - moved to AdditionalFeaturesPage)
  // Form data (removed - moved to AdditionalFeaturesPage)
  
  // 处理状态
  bool _isProcessing = false;

  // 服务
  late final IdRecognitionService _idService;

  // ============================================
  // 生命周期方法
  // ============================================
  
  @override
  void initState() {
    super.initState();
    
    // Create AI parser service for enhanced field extraction
    final aiService = AiParserService(
      // apiUrl: 'https://amg-backend-dev-api3.azurewebsites.net/api/chat',
      apiUrl: 'http://10.0.2.2:8006/api/chat',  // Android emulator localhost alias
      apiKey: '3razU1sHTAPGdCL5tKSMpOIbkxgJ9E6j',
    );
    
    // Initialize ID service with AI enhancement
    _idService = IdRecognitionService(
      ocrProvider: MlKitOcrAdapter(),
      aiParserService: aiService,
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
  // UI 构建方法
  // ============================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xff4a5f8c),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan ID',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background with gradient
          if (_capturedImage != null)
            Image.file(_capturedImage!, fit: BoxFit.cover)
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xff4a5f8c).withOpacity(0.3),
                    Colors.black,
                  ],
                ),
              ),
            ),
          
          // Dark overlay
          Container(color: Colors.black.withOpacity(0.5)),
          
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                // Top header with "Front of ID" text
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      Text(
                        _result == null ? 'Front of ID' : 'Document Scanned',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.white),
                        onPressed: () {
                          showInfoDialog(
                            'Scan Instructions',
                            'Tap the yellow frame to capture your ID card.\n\n'
                            'Supported: Hong Kong ID, China ID, Passport',
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // ID Badge Icon with yellow border
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xffffb800), width: 3),
                    borderRadius: BorderRadius.circular(12),
                    color: _result != null ? const Color(0xffffb800).withOpacity(0.2) : null,
                  ),
                  child: Icon(
                    _result != null ? Icons.check_circle : Icons.badge_outlined,
                    color: _result != null ? const Color(0xffffb800) : const Color(0xff4a5f8c),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Main scanning frame (yellow border)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: _isProcessing ? null : captureDocument,
                    child: Container(
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xffffb800),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: _capturedImage == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 60,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tap to capture ID',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _capturedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Action buttons row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : captureDocument,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Capture'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffffb800),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : chooseFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff4a5f8c),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Results section (only show after scanning)
                if (_result != null) ...[
                  _buildParsedResultsCard(),
                  const SizedBox(height: 16),
                  
                  // Process Document button - jump to Additional Features
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdditionalFeaturesPage(
                              initialResult: _result, // 传递扫描结果
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_suggest, size: 24),
                      label: const Text(
                        'Process Document',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffffb800),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xffffb800).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Raw text section
                if (_result != null && _result!.rawText != null) ...[
                  _buildRawTextCard(),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
          
          // Loading overlay
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.home_outlined, color: Colors.grey[600], size: 28),
            Icon(Icons.description_outlined, color: Colors.grey[600], size: 28),
            Icon(Icons.folder_outlined, color: Colors.grey[600], size: 28),
            Icon(Icons.people_outline, color: Colors.grey[600], size: 28),
            Icon(Icons.local_offer_outlined, color: Colors.grey[600], size: 28),
            Icon(Icons.emoji_events_outlined, color: Colors.grey[600], size: 28),
          ],
        ),
      ),
    );
  }


  /// 构建原始文本卡片
  Widget _buildRawTextCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xff1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff4a5f8c).withOpacity(0.3)),
      ),
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
                    const Color(0xff1a1a1a),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
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
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
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
                        'Raw OCR Output:',
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffffb800).withOpacity(0.5)),
      ),
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
                    ? const Color(0xffffb800)
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
            const Divider(color: Color(0xff4a5f8c), height: 24),
            for (var id in _result!.parsedIds!)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id.type,
                    style: const TextStyle(
                      color: Color(0xffffb800),
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

