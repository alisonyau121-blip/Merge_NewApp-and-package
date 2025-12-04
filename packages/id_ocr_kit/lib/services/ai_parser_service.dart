import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// AI-powered ID card parser service using Google API
/// 
/// This service calls an external API to intelligently parse
/// raw OCR text and extract structured fields from ID cards.
class AiParserService {
  static final _log = Logger('AiParserService');
  
  final String apiUrl;
  final String apiKey;
  
  /// Creates AI parser service with API configuration
  /// 
  /// [apiUrl] - The chat API endpoint
  /// [apiKey] - The API authentication key
  AiParserService({
    required this.apiUrl,
    required this.apiKey,
  });
  
  /// Parse HKID card fields using AI
  /// 
  /// Returns a map of extracted fields or empty map if parsing fails
  Future<Map<String, String>> parseHkid(String rawText) async {
    _log.info('Parsing HKID with AI...');
    
    final prompt = _buildHkidPrompt(rawText);
    final response = await _callApi(prompt);
    
    if (response == null) {
      _log.warning('API call failed for HKID parsing');
      return {};
    }
    
    return _extractHkidFields(response);
  }
  
  /// Parse China ID card fields using AI
  /// 
  /// Returns a map of extracted fields or empty map if parsing fails
  Future<Map<String, String>> parseChinaId(String rawText) async {
    _log.info('Parsing China ID with AI...');
    
    final prompt = _buildChinaIdPrompt(rawText);
    final response = await _callApi(prompt);
    
    if (response == null) {
      _log.warning('API call failed for China ID parsing');
      return {};
    }
    
    return _extractChinaIdFields(response);
  }
  
  /// Parse Passport fields using AI
  /// 
  /// Returns a map of extracted fields or empty map if parsing fails
  Future<Map<String, String>> parsePassport(String rawText) async {
    _log.info('Parsing Passport with AI...');
    
    final prompt = _buildPassportPrompt(rawText);
    final response = await _callApi(prompt);
    
    if (response == null) {
      _log.warning('API call failed for Passport parsing');
      return {};
    }
    
    return _extractPassportFields(response);
  }
  
  /// Build HKID parsing prompt
  String _buildHkidPrompt(String scannedText) {
    return '''
Below is the scanned text from a Hong Kong ID card. Please extract and recognize the person's information.

Scanned Text:
$scannedText

Please return a JSON object with the following fields:
- chineseName: The person's name in Chinese characters (or empty string if not found)
- englishName: The person's name in English (or empty string if not found)
- dateOfBirth: Date of birth in format DD-MM-YYYY (or empty string if not found)
- hkidNumber: Hong Kong ID number (e.g., C668668(E)) (or empty string if not found)
- dateOfIssue: Date the ID was issued (or empty string if not found)
- gender: Gender (Male/Female) (or empty string if not found)

Return ONLY valid JSON, no additional text.
''';
  }
  
  /// Build China ID parsing prompt
  String _buildChinaIdPrompt(String scannedText) {
    return '''
Below is the scanned text from a China Resident ID card. Please extract and recognize the person's information.

Scanned Text:
$scannedText

Please return a JSON object with the following fields:
- chineseName: The person's name in Chinese characters (or empty string if not found)
- idNumber: 18-digit ID number (or empty string if not found)
- dateOfBirth: Date of birth in format YYYY-MM-DD (or empty string if not found)
- gender: Gender (Male/Female) (or empty string if not found)
- address: Residential address (or empty string if not found)
- nationality: Nationality/Ethnicity (or empty string if not found)
- issuingAuthority: Issuing authority (or empty string if not found)

Return ONLY valid JSON, no additional text.
''';
  }
  
  /// Build Passport parsing prompt
  String _buildPassportPrompt(String scannedText) {
    return '''
Below is the scanned text from a Passport (MRZ). Please extract and recognize the person's information.

Scanned Text:
$scannedText

Please return a JSON object with the following fields:
- surname: Surname/Family name (or empty string if not found)
- givenNames: Given names (or empty string if not found)
- passportNumber: Passport number (or empty string if not found)
- nationality: Nationality code (3 letters) (or empty string if not found)
- dateOfBirth: Date of birth in format YYYY-MM-DD (or empty string if not found)
- sex: Sex (M/F) (or empty string if not found)
- expiryDate: Expiry date in format YYYY-MM-DD (or empty string if not found)
- countryCode: Issuing country code (or empty string if not found)

Return ONLY valid JSON, no additional text.
''';
  }
  
  /// Call the AI API with a prompt
  /// 
  /// Returns the API response as a string, or null if the call fails
  Future<String?> _callApi(String prompt) async {
    try {
      _log.info('Calling AI API...');
      _log.info('Prompt preview: ${prompt.substring(0, prompt.length > 100 ? 100 : prompt.length)}...');
      
      final requestBody = jsonEncode({
        'prompt': prompt,  // Changed from 'message' to 'prompt'
      });
      
      _log.info('Request body length: ${requestBody.length} bytes');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'AMG-API-Key': apiKey,
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 30));
      
      _log.info('API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        _log.info('API call successful');
        _log.info('Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
        return response.body;
      } else {
        _log.warning('API returned status code: ${response.statusCode}');
        _log.warning('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      _log.severe('Error calling API: $e');
      return null;
    }
  }
  
  /// Extract HKID fields from API response
  Map<String, String> _extractHkidFields(String apiResponse) {
    try {
      // Try to parse JSON from response
      final json = _extractJson(apiResponse);
      if (json == null) return {};
      
      final fields = <String, String>{};
      
      // Map API fields to display fields
      if (json['chineseName'] != null && json['chineseName'].toString().isNotEmpty) {
        fields['Chinese Name'] = json['chineseName'].toString();
      }
      if (json['englishName'] != null && json['englishName'].toString().isNotEmpty) {
        fields['English Name'] = json['englishName'].toString();
      }
      if (json['dateOfBirth'] != null && json['dateOfBirth'].toString().isNotEmpty) {
        fields['Date of Birth'] = json['dateOfBirth'].toString();
      }
      if (json['hkidNumber'] != null && json['hkidNumber'].toString().isNotEmpty) {
        fields['ID Number'] = json['hkidNumber'].toString();
      }
      if (json['dateOfIssue'] != null && json['dateOfIssue'].toString().isNotEmpty) {
        fields['Date of Issue'] = json['dateOfIssue'].toString();
      }
      if (json['gender'] != null && json['gender'].toString().isNotEmpty) {
        fields['Gender'] = json['gender'].toString();
      }
      
      _log.info('Extracted ${fields.length} fields from HKID');
      return fields;
    } catch (e) {
      _log.severe('Error extracting HKID fields: $e');
      return {};
    }
  }
  
  /// Extract China ID fields from API response
  Map<String, String> _extractChinaIdFields(String apiResponse) {
    try {
      _log.info('Extracting China ID fields from API response...');
      final json = _extractJson(apiResponse);
      
      if (json == null) {
        _log.warning('Failed to extract JSON from API response');
        return {};
      }
      
      _log.info('Parsed JSON keys: ${json.keys.toList()}');
      
      final fields = <String, String>{};
      
      if (json['chineseName'] != null && json['chineseName'].toString().isNotEmpty) {
        fields['Chinese Name'] = json['chineseName'].toString();
        _log.info('Extracted Chinese Name: ${fields['Chinese Name']}');
      }
      if (json['idNumber'] != null && json['idNumber'].toString().isNotEmpty) {
        fields['ID Number'] = json['idNumber'].toString();
        _log.info('Extracted ID Number: ${fields['ID Number']}');
      }
      if (json['dateOfBirth'] != null && json['dateOfBirth'].toString().isNotEmpty) {
        fields['Date of Birth'] = json['dateOfBirth'].toString();
        _log.info('Extracted Date of Birth: ${fields['Date of Birth']}');
      }
      if (json['gender'] != null && json['gender'].toString().isNotEmpty) {
        fields['Gender'] = json['gender'].toString();
        _log.info('Extracted Gender: ${fields['Gender']}');
      }
      if (json['address'] != null && json['address'].toString().isNotEmpty) {
        fields['Address'] = json['address'].toString();
        _log.info('Extracted Address: ${fields['Address']}');
      }
      if (json['nationality'] != null && json['nationality'].toString().isNotEmpty) {
        fields['Nationality'] = json['nationality'].toString();
        _log.info('Extracted Nationality: ${fields['Nationality']}');
      }
      if (json['issuingAuthority'] != null && json['issuingAuthority'].toString().isNotEmpty) {
        fields['Issuing Authority'] = json['issuingAuthority'].toString();
        _log.info('Extracted Issuing Authority: ${fields['Issuing Authority']}');
      }
      
      _log.info('Extracted ${fields.length} fields from China ID: ${fields.keys.toList()}');
      return fields;
    } catch (e) {
      _log.severe('Error extracting China ID fields: $e');
      return {};
    }
  }
  
  /// Extract Passport fields from API response
  Map<String, String> _extractPassportFields(String apiResponse) {
    try {
      final json = _extractJson(apiResponse);
      if (json == null) return {};
      
      final fields = <String, String>{};
      
      if (json['surname'] != null && json['surname'].toString().isNotEmpty) {
        fields['Surname'] = json['surname'].toString();
      }
      if (json['givenNames'] != null && json['givenNames'].toString().isNotEmpty) {
        fields['Given Names'] = json['givenNames'].toString();
      }
      if (json['passportNumber'] != null && json['passportNumber'].toString().isNotEmpty) {
        fields['Passport Number'] = json['passportNumber'].toString();
      }
      if (json['nationality'] != null && json['nationality'].toString().isNotEmpty) {
        fields['Nationality'] = json['nationality'].toString();
      }
      if (json['dateOfBirth'] != null && json['dateOfBirth'].toString().isNotEmpty) {
        fields['Date of Birth'] = json['dateOfBirth'].toString();
      }
      if (json['sex'] != null && json['sex'].toString().isNotEmpty) {
        fields['Sex'] = json['sex'].toString();
      }
      if (json['expiryDate'] != null && json['expiryDate'].toString().isNotEmpty) {
        fields['Expiry Date'] = json['expiryDate'].toString();
      }
      if (json['countryCode'] != null && json['countryCode'].toString().isNotEmpty) {
        fields['Country Code'] = json['countryCode'].toString();
      }
      
      _log.info('Extracted ${fields.length} fields from Passport');
      return fields;
    } catch (e) {
      _log.severe('Error extracting Passport fields: $e');
      return {};
    }
  }
  
  /// Extract JSON object from API response
  /// 
  /// The API might return JSON wrapped in markdown code blocks or other text
  Map<String, dynamic>? _extractJson(String response) {
    _log.info('Attempting to extract JSON from response (length: ${response.length})');
    
    try {
      // Try direct JSON parse first
      _log.info('Trying direct JSON parse...');
      final json = jsonDecode(response) as Map<String, dynamic>;
      _log.info('Direct JSON parse successful!');
      
      // Check if the response has a 'result' field with JSON string
      if (json.containsKey('result') && json['result'] is String) {
        _log.info('Found "result" field containing JSON string, parsing nested JSON...');
        try {
          final nestedJson = jsonDecode(json['result'] as String) as Map<String, dynamic>;
          _log.info('Nested JSON parse successful!');
          return nestedJson;
        } catch (e) {
          _log.warning('Failed to parse nested JSON from result field: $e');
          return json; // Return original if nested parse fails
        }
      }
      
      return json;
    } catch (e) {
      _log.info('Direct JSON parse failed: $e');
      
      // If that fails, try to extract JSON from markdown code blocks
      _log.info('Trying markdown JSON block extraction...');
      final jsonPattern = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```', multiLine: true);
      final match = jsonPattern.firstMatch(response);
      
      if (match != null) {
        _log.info('Found JSON in markdown block');
        try {
          final json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
          _log.info('Markdown JSON parse successful!');
          return json;
        } catch (e) {
          _log.warning('Failed to parse JSON from markdown block: $e');
        }
      }
      
      // Try to find any JSON object in the response
      _log.info('Trying to find JSON object anywhere in response...');
      final objectPattern = RegExp(r'\{[\s\S]*\}', multiLine: true);
      final objectMatch = objectPattern.firstMatch(response);
      
      if (objectMatch != null) {
        _log.info('Found potential JSON object');
        try {
          final json = jsonDecode(objectMatch.group(0)!) as Map<String, dynamic>;
          _log.info('Object JSON parse successful!');
          return json;
        } catch (e) {
          _log.warning('Failed to parse JSON object: $e');
        }
      }
      
      _log.warning('Could not extract JSON from response');
      _log.warning('Response preview: ${response.substring(0, response.length > 500 ? 500 : response.length)}');
      return null;
    }
  }
}

