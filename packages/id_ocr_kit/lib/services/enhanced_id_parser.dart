import 'package:logging/logging.dart';
import '../models/id_parsers.dart';
import 'ai_parser_service.dart';

/// Enhanced ID parser that combines pattern detection with AI parsing
/// 
/// This parser uses a two-step approach:
/// 1. Pattern detection: Use regex to identify ID type
/// 2. AI parsing: Use API to extract detailed fields
class EnhancedIdParser {
  static final _log = Logger('EnhancedIdParser');
  
  final AiParserService? _aiService;
  
  /// Creates enhanced parser with optional AI service
  /// 
  /// If [aiService] is null, falls back to basic pattern matching
  EnhancedIdParser({AiParserService? aiService}) : _aiService = aiService;
  
  /// Parse all ID types from text with AI enhancement
  /// 
  /// Returns a list of parsed IDs with enriched data from AI
  Future<List<IdParseResult>> parseAll(String text) async {
    final results = <IdParseResult>[];
    
    // Step 1: Detect ID types using pattern matching
    final detectedTypes = _detectIdTypes(text);
    
    if (detectedTypes.isEmpty) {
      _log.info('No ID patterns detected in text');
      return results;
    }
    
    _log.info('Detected ID types: $detectedTypes');
    
    // Step 2: Parse each detected type with AI enhancement
    for (final type in detectedTypes) {
      IdParseResult? result;
      
      switch (type) {
        case 'HKID':
          result = await _parseHkidWithAi(text);
          break;
        case 'ChinaID':
          result = await _parseChinaIdWithAi(text);
          break;
        case 'Passport':
          result = await _parsePassportWithAi(text);
          break;
      }
      
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }
  
  /// Detect ID types using pattern matching
  /// 
  /// Performance optimized: Returns ONLY the first matched ID type
  /// Priority order: HKID > China ID > Passport
  /// 
  /// This prevents multiple detections and reduces API calls
  List<String> _detectIdTypes(String text) {
    // Check for HKID pattern first (highest priority)
    if (HkidParser.parse(text) != null) {
      _log.info('Detected: HKID');
      return ['HKID'];  // Return immediately
    }
    
    // Check for China ID pattern (second priority)
    if (ChinaIdParser.parse(text) != null) {
      _log.info('Detected: China ID');
      return ['ChinaID'];  // Return immediately
    }
    
    // Check for Passport MRZ pattern (lowest priority)
    if (PassportMrzParser.parse(text) != null) {
      _log.info('Detected: Passport');
      return ['Passport'];  // Return immediately
    }
    
    _log.info('No ID pattern detected');
    return [];  // No ID found
  }
  
  /// Parse HKID with AI enhancement
  Future<HkidResult?> _parseHkidWithAi(String text) async {
    try {
      // Get basic info from pattern matching
      final basicResult = HkidParser.parse(text);
      if (basicResult == null) return null;
      
      // If AI service is available, enhance with AI parsing
      if (_aiService != null) {
        _log.info('Enhancing HKID with AI parsing...');
        final aiFields = await _aiService!.parseHkid(text);
        
        if (aiFields.isNotEmpty) {
          // Merge AI fields with basic fields
          final mergedFields = <String, String>{
            ...aiFields, // AI fields first (priority)
            ...basicResult.fields, // Basic fields as fallback
          };
          
          // Add validation status
          mergedFields['Validation'] = basicResult.isValid ? '✓ Valid' : '✗ Invalid';
          
          _log.info('Enhanced HKID with ${aiFields.length} AI fields');
          
          return HkidResult(
            fields: mergedFields,
            isValid: basicResult.isValid,
          );
        }
      }
      
      // Fallback to basic parsing if AI fails or unavailable
      _log.info('Using basic HKID parsing');
      return basicResult;
    } catch (e) {
      _log.severe('Error parsing HKID with AI: $e');
      // Return basic result on error
      return HkidParser.parse(text);
    }
  }
  
  /// Parse China ID with AI enhancement
  Future<ChinaIdResult?> _parseChinaIdWithAi(String text) async {
    try {
      final basicResult = ChinaIdParser.parse(text);
      if (basicResult == null) return null;
      
      if (_aiService != null) {
        _log.info('Enhancing China ID with AI parsing...');
        final aiFields = await _aiService!.parseChinaId(text);
        
        if (aiFields.isNotEmpty) {
          final mergedFields = <String, String>{
            ...aiFields,
            ...basicResult.fields,
          };
          
          mergedFields['Validation'] = basicResult.isValid ? '✓ Valid' : '✗ Invalid';
          
          _log.info('Enhanced China ID with ${aiFields.length} AI fields');
          
          return ChinaIdResult(
            fields: mergedFields,
            isValid: basicResult.isValid,
          );
        }
      }
      
      _log.info('Using basic China ID parsing');
      return basicResult;
    } catch (e) {
      _log.severe('Error parsing China ID with AI: $e');
      return ChinaIdParser.parse(text);
    }
  }
  
  /// Parse Passport with AI enhancement
  Future<PassportResult?> _parsePassportWithAi(String text) async {
    try {
      final basicResult = PassportMrzParser.parse(text);
      if (basicResult == null) return null;
      
      if (_aiService != null) {
        _log.info('Enhancing Passport with AI parsing...');
        final aiFields = await _aiService!.parsePassport(text);
        
        if (aiFields.isNotEmpty) {
          final mergedFields = <String, String>{
            ...aiFields,
            ...basicResult.fields,
          };
          
          mergedFields['Validation'] = basicResult.isValid ? '✓ Valid' : '✗ Invalid';
          
          _log.info('Enhanced Passport with ${aiFields.length} AI fields');
          
          return PassportResult(
            fields: mergedFields,
            isValid: basicResult.isValid,
          );
        }
      }
      
      _log.info('Using basic Passport parsing');
      return basicResult;
    } catch (e) {
      _log.severe('Error parsing Passport with AI: $e');
      return PassportMrzParser.parse(text);
    }
  }
}

