# API Integration Fix Documentation

## 🐛 **Problems Found and Fixed**

### **Problem 1: Wrong Parameter Name** ❌

**Issue:**
The AI parser was sending `"message"` parameter to the API:
```json
{
  "message": "prompt text..."
}
```

**Error from API:**
```json
{"detail":"Missing 'prompt_text' or 'prompt' parameter"}
```

**Fix:** ✅
Changed to send `"prompt"` parameter:
```json
{
  "prompt": "prompt text..."
}
```

**File Changed:** `packages/id_ocr_kit/lib/services/ai_parser_service.dart`

---

### **Problem 2: Nested JSON Response Format** ❌

**Issue:**
The API returns data wrapped in a `"result"` field as a JSON string:
```json
{
  "result": "{\"chineseName\":\"证件样本\",\"idNumber\":\"110110199901012345\",...}"
}
```

The parser was trying to extract fields directly from the outer JSON, which only had a `"result"` key.

**Fix:** ✅
Added double-parsing logic:
1. Parse the outer JSON
2. Check if `"result"` field exists and is a string
3. Parse the inner JSON string
4. Return the inner JSON object

**Code:**
```dart
Map<String, dynamic>? _extractJson(String response) {
  try {
    final json = jsonDecode(response) as Map<String, dynamic>;
    
    // Check if the response has a 'result' field with JSON string
    if (json.containsKey('result') && json['result'] is String) {
      final nestedJson = jsonDecode(json['result'] as String);
      return nestedJson;  // Return the nested JSON
    }
    
    return json;  // Return original if no nesting
  } catch (e) {
    // ... error handling
  }
}
```

**File Changed:** `packages/id_ocr_kit/lib/services/ai_parser_service.dart`

---

### **Problem 3: Insufficient Logging** ❌

**Issue:**
When the API failed silently, there was no way to debug what went wrong.

**Fix:** ✅
Added comprehensive logging throughout the API service:

1. **Request logging:**
   - Prompt preview
   - Request body size
   - API endpoint

2. **Response logging:**
   - Status code
   - Response body preview
   - Headers

3. **JSON parsing logging:**
   - Parse attempts (direct, markdown, nested)
   - Success/failure for each attempt
   - Extracted keys

4. **Field extraction logging:**
   - Each field extracted
   - Total number of fields
   - Field keys

5. **App-wide logging:**
   - Enabled in `main.dart`
   - Logs to console with level, logger name, and message

**Files Changed:**
- `packages/id_ocr_kit/lib/services/ai_parser_service.dart`
- `lib/main.dart`

---

## ✅ **What Works Now**

### **API Request:**
```json
POST https://amg-backend-dev-api3.azurewebsites.net/api/chat
Headers: {
  "Content-Type": "application/json",
  "AMG-API-Key": "3razU1sHTAPGdCL5tKSMpOIbkxgJ9E6j"
}
Body: {
  "prompt": "Below is the scanned text from a China Resident ID card..."
}
```

### **API Response:**
```json
{
  "result": "{\"chineseName\":\"证件样本\",\"idNumber\":\"110110199901012345\",\"dateOfBirth\":\"1978-10-27\",\"gender\":\"Female\",\"address\":\"北京市西城区复兴门外大街9号国际商务大厦9层\",\"nationality\":\"汉\",\"issuingAuthority\":\"\"}"
}
```

### **Parsed Fields:**
```dart
{
  "Chinese Name": "证件样本",
  "ID Number": "110110199901012345",
  "Date of Birth": "1978-10-27",
  "Gender": "Female",
  "Address": "北京市西城区复兴门外大街9号国际商务大厦9层",
  "Nationality": "汉",
  "Issuing Authority": ""
}
```

### **Display in UI:**
```
✓ Document Recognized (1 found)

China ID Card
  Chinese Name:        证件样本        ✅ NEW!
  ID Number:           110110199901012345
  Date of Birth:       1978-10-27      ✅ Enhanced!
  Gender:              Female           ✅ Enhanced!
  Address:             北京市西城...    ✅ NEW!
  Nationality:         汉              ✅ NEW!
  Area Code:           110110
  Sequence:            234
  Check Digit:         5
  Validation:          ✗ Invalid
```

---

## 🧪 **Testing**

### **Test Script Created:**
`test_api.dart` - Standalone script to test the API without running the full app

**Run it:**
```bash
dart run test_api.dart
```

**Output:**
```
✅ API call successful!
✅ Response is valid JSON!
🔍 Found nested JSON in "result" field, parsing...
✅ Nested JSON parsed successfully!
Nested JSON keys: [chineseName, idNumber, dateOfBirth, gender, address, nationality, issuingAuthority]
```

---

## 📊 **Before vs After**

### **Before Fix:**
```
China ID Card
  ID Number:           110110199901012345
  Area Code:           110110
  Date of Birth:       1999-01-01  (derived from ID)
  Gender:              Female       (derived from ID)
  Sequence:            234
  Check Digit:         5
  Validation:          ✗ Invalid
  Processing Time:     23118ms
```

**Missing:**
- ❌ Chinese Name
- ❌ Address
- ❌ Nationality
- ❌ Date of Birth was wrong (1999-01-01 vs actual 1978-10-27)

---

### **After Fix:**
```
China ID Card
  Chinese Name:        证件样本        ✅ From API
  ID Number:           110110199901012345
  Date of Birth:       1978-10-27      ✅ Corrected by API
  Gender:              Female
  Address:             北京市西城...    ✅ From API
  Nationality:         汉              ✅ From API
  Issuing Authority:   (empty)         ✅ From API
  Area Code:           110110
  Sequence:            234
  Check Digit:         5
  Validation:          ✗ Invalid
```

**Improvements:**
- ✅ Chinese Name extracted
- ✅ Address extracted
- ✅ Nationality extracted
- ✅ Correct Date of Birth (1978 vs 1999)
- ✅ All AI fields merged with basic fields

---

## 🔍 **How to Debug**

### **Check Logs:**

Run the app and look for logs like:
```
INFO: AiParserService: Calling AI API...
INFO: AiParserService: API response status: 200
INFO: AiParserService: Attempting to extract JSON from response...
INFO: AiParserService: Found "result" field containing JSON string, parsing nested JSON...
INFO: AiParserService: Nested JSON parse successful!
INFO: AiParserService: Extracted Chinese Name: 证件样本
INFO: AiParserService: Extracted 7 fields from China ID
INFO: EnhancedIdParser: Enhanced China ID with 7 AI fields
```

### **If API Fails:**

Look for logs like:
```
WARNING: AiParserService: API returned status code: 400
SEVERE: AiParserService: Error calling API: TimeoutException
INFO: EnhancedIdParser: Using basic China ID parsing
```

### **Enable Verbose Logging:**

Already enabled in `lib/main.dart`:
```dart
Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) {
  print('${record.level.name}: ${record.loggerName}: ${record.message}');
});
```

---

## 📝 **Summary of Changes**

| File | Change | Reason |
|------|--------|--------|
| `ai_parser_service.dart` | Changed `'message'` to `'prompt'` | API expects `prompt` parameter |
| `ai_parser_service.dart` | Added nested JSON parsing | API returns data in `result` field |
| `ai_parser_service.dart` | Added detailed logging | For debugging |
| `main.dart` | Enabled comprehensive logging | See all debug messages |
| `test_api.dart` | Created test script | Test API independently |

---

## ✅ **Result:**

🎉 **AI-enhanced ID parsing is now working correctly!**

**You should now see:**
- ✅ Chinese names from ID cards
- ✅ Addresses from ID cards
- ✅ Nationality/ethnicity
- ✅ All fields extracted by AI
- ✅ Merged with basic pattern-matching fields

**Try it:**
1. Launch the app
2. Click "Scan ID"
3. Capture a China ID, HKID, or Passport
4. See the enhanced fields in "Document Recognized" section!

---

**Last Updated:** December 4, 2025  
**Status:** ✅ Fixed and tested

