import 'package:flutter/material.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';
import 'package:logging/logging.dart';

/// 姓名提取 Mixin
/// 包含从 OCR 结果中提取姓名的所有逻辑
mixin NameExtractionMixin<T extends StatefulWidget> on State<T> {
  // 需要子类提供 logger
  Logger get logger;
  
  // 需要子类提供 OCR 结果
  IdRecognitionResult? get ocrResult;

  /// 从文档中提取姓名（主入口）
  String extractNameFromDocument() {
    if (ocrResult == null || !ocrResult!.hasIds) {
      return '';
    }
    
    try {
      for (final id in ocrResult!.parsedIds!) {
        // 护照：组合 surname 和 given names
        if (id.type == 'Passport') {
          final surname = id.fields['Surname']?.toString() ?? '';
          final givenNames = id.fields['Given Names']?.toString() ?? '';
          
          if (surname.isNotEmpty || givenNames.isNotEmpty) {
            final fullName = '$givenNames $surname'.trim();
            logger.info('Extracted name from Passport: $fullName');
            return fullName;
          }
        }
        
        // HKID 和中国身份证：从原始文本提取
        if (id.type == 'HKID - Hong Kong ID Card' || id.type == 'China ID Card') {
          if (ocrResult!.rawText != null) {
            final name = extractNameFromRawText(ocrResult!.rawText!, id.type);
            if (name.isNotEmpty) {
              return name;
            }
          }
        }
      }
      
      logger.warning('No name found in parsed documents');
      return '';
    } catch (e) {
      logger.severe('Error extracting name from document', e);
      return '';
    }
  }

  /// 从原始 OCR 文本中提取姓名（关键词策略）
  String extractNameFromRawText(String rawText, String idType) {
    try {
      logger.info('🔍 Extracting name from OCR text (Type: $idType)...');
      
      // 分行处理
      final lines = rawText.split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      // 定义不同证件类型的姓名关键词
      final nameKeywords = <String, List<String>>{
        'Passport': [
          'Surname', 'SURNAME', 'Surname/Nom',
          'Given names', 'GIVEN NAMES', 'Given Names', 'Given names/Prénoms',
          'Name', 'NAME', 'Full name', 'FULL NAME',
        ],
        'HKID': [
          '姓名', 'Name', 'NAME', '姓名：', 'Name:',
          '中文姓名', '英文姓名',
        ],
        'China ID': [
          '姓名', 'Name', 'NAME', '姓名：',
          '中文姓名',
        ],
      };
      
      String? surname;
      String? givenNames;
      String? fullName;
      
      // 策略：找到关键词 → 提取下一行数据
      for (int i = 0; i < lines.length; i++) {
        final currentLine = lines[i];
        
        // 检查 Surname 关键词（护照）
        if (containsKeyword(currentLine, ['Surname', 'SURNAME', 'Surname/Nom'])) {
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1];
            if (isValidName(nextLine)) {
              surname = nextLine;
              logger.info('✅ Found surname: $surname');
            }
          }
        }
        
        // 检查 Given Names 关键词（护照）
        if (containsKeyword(currentLine, ['Given names', 'GIVEN NAMES', 'Given Names', 'Given names/Prénoms'])) {
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1];
            if (isValidName(nextLine)) {
              givenNames = nextLine;
              logger.info('✅ Found given names: $givenNames');
            }
          }
        }
        
        // 检查通用 Name 关键词（HKID/中国身份证）
        if (containsKeyword(currentLine, ['姓名', 'Name', 'NAME', '中文姓名', '英文姓名']) &&
            !currentLine.contains('Given') && !currentLine.contains('Surname')) {
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1];
            if (isValidName(nextLine)) {
              fullName = nextLine;
              logger.info('✅ Found full name: $fullName');
              
              // HKID 可能有中英文双语姓名
              if (i + 2 < lines.length) {
                final lineAfterNext = lines[i + 2];
                if (isValidName(lineAfterNext) && !containsKeyword(lineAfterNext, nameKeywords.values.expand((x) => x).toList())) {
                  fullName = '$fullName $lineAfterNext'.trim();
                  logger.info('✅ Combined with English/Chinese name: $fullName');
                }
              }
              break;
            }
          }
        }
      }
      
      // 后备方案：如果关键词策略失败，使用模式匹配
      if (surname == null && givenNames == null && fullName == null) {
        logger.warning('⚠️ Keyword strategy failed, trying pattern matching...');
        fullName = extractNameByPattern(lines);
      }
      
      // 构建最终结果
      String result = '';
      
      // 护照：组合 surname 和 given names
      if (surname != null || givenNames != null) {
        result = '${givenNames ?? ''} ${surname ?? ''}'.trim();
      }
      
      // HKID/中国身份证：使用完整姓名
      if (result.isEmpty && fullName != null) {
        result = fullName;
      }
      
      if (result.isNotEmpty) {
        logger.info('✅ Final extracted name: $result');
      } else {
        logger.warning('❌ No name extracted from OCR text');
      }
      
      return result;
    } catch (e) {
      logger.severe('Error extracting name from raw text', e);
      return '';
    }
  }

  /// 检查行是否包含关键词
  bool containsKeyword(String line, List<String> keywords) {
    final lineUpper = line.toUpperCase();
    for (final keyword in keywords) {
      if (lineUpper.contains(keyword.toUpperCase())) {
        return true;
      }
    }
    return false;
  }

  /// 验证是否为有效姓名
  bool isValidName(String line) {
    if (line.length < 2 || line.length > 50) return false;
    
    // 拒绝身份证号码
    if (RegExp(r'^[A-Z]{1,2}\d{6}\(?\d?\)?$').hasMatch(line)) return false; // HKID
    if (RegExp(r'^\d{17,18}[\dXx]?$').hasMatch(line)) return false; // 中国身份证
    if (RegExp(r'^[A-Z0-9]{6,9}$').hasMatch(line)) return false; // 护照号
    
    // 拒绝日期
    if (RegExp(r'\d{4}[-/年]\d{2}[-/月]\d{2}').hasMatch(line)) return false;
    if (RegExp(r'\d{2}[-/]\d{2}[-/]\d{4}').hasMatch(line)) return false;
    if (RegExp(r'^\d{6,8}$').hasMatch(line)) return false; // YYMMDD 或 YYYYMMDD
    
    // 拒绝常见文档文字
    final excludedWords = [
      'HONG KONG', 'IDENTITY CARD', 'CARD', 'PERMANENT', 'RESIDENT',
      'CHINA', 'REPUBLIC', 'PASSPORT', 'DOCUMENT', 'NUMBER', 'DATE',
      'NATIONALITY', 'BIRTH', 'EXPIRY', 'ISSUE',
      '香港', '中國', '中国', '身份證', '身份证', '居民', '號碼', '号码',
      '性別', '性别', '出生', '簽發', '签发', '有效',
      'Male', 'Female', 'M/', 'F/',
    ];
    
    final lineUpper = line.toUpperCase();
    for (final word in excludedWords) {
      if (lineUpper.contains(word.toUpperCase())) return false;
    }
    
    // 接受有效姓名格式
    // 中文姓名：2-4 个汉字
    if (RegExp(r'^[\u4e00-\u9fa5]{2,4}$').hasMatch(line)) return true;
    
    // 英文姓名：字母 + 可能的空格/连字符/撇号
    if (RegExp(r"^[A-Za-z\s\-']+$").hasMatch(line) && line.split(RegExp(r'\s+')).length <= 5) {
      return true;
    }
    
    // 混合（中文 + 英文）
    if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(line) && RegExp(r'[A-Za-z]').hasMatch(line)) {
      return true;
    }
    
    return false;
  }

  /// 后备方案：使用模式匹配提取姓名
  String extractNameByPattern(List<String> lines) {
    for (final line in lines) {
      if (isValidName(line)) {
        logger.info('📝 Pattern match found: $line');
        return line;
      }
    }
    return '';
  }
}


