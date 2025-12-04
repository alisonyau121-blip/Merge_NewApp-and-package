# How to Use AI-Enhanced ID Parser

## 🚀 Quick Start

The AI parser is **already integrated** and **ready to use**! No additional setup required.

---

## 📱 User Flow

### **Step 1: Open the App**

Launch the Demo Sample app on your device/emulator.

### **Step 2: Navigate to Scan ID**

From Home Page → Click **"Scan ID"** (yellow button)

### **Step 3: Capture or Select ID Photo**

- **Option A:** Click **"Capture"** to take a photo with camera
- **Option B:** Click **"Gallery"** to select from photo library

### **Step 4: Wait for Processing**

You'll see:
```
Processing...
```

**What's happening behind the scenes:**
1. ⚡ OCR extracts raw text (1-3 seconds)
2. 🔍 Pattern detection identifies ID type
3. 🤖 AI API parses fields (2-5 seconds)
4. ✨ Fields merge and display

**Total time: 3-8 seconds**

### **Step 5: View Results**

**Document Recognized Section:**

```
✓ Document Recognized (1 found)

HKID - Hong Kong ID Card
  Chinese Name:     陳大文         ← AI extracted!
  English Name:     CHAN TAI MAN   ← AI extracted!
  Gender:           Male            ← AI extracted!
  Date of Birth:    26-05-1990     ← AI extracted!
  Date of Issue:    19-05-26       ← AI extracted!
  ID Number:        M9259517
  Letter Prefix:    M
  Digits:           925951
  Check Digit:      7
  Validation:       ✓ Valid
```

---

## 🎯 Supported ID Types

### **1. Hong Kong ID Card (HKID)**

**Extracted Fields:**
- ✅ Chinese Name (姓名)
- ✅ English Name
- ✅ Gender (性別)
- ✅ Date of Birth (出生日期)
- ✅ Date of Issue (簽發日期)
- ✅ ID Number (身份證號碼)

**Example Card:**
```
香港特別行政區
HONG KONG SPECIAL ADMINISTRATIVE REGION

姓名 Name        陳大文 CHAN TAI MAN
性別 Sex         M
出生日期          26-05-1990
簽發日期          19-05-26
身份證號碼        M9259517(7)
```

---

### **2. China Resident ID Card**

**Extracted Fields:**
- ✅ Chinese Name (姓名)
- ✅ ID Number (18 digits)
- ✅ Date of Birth (derived from ID)
- ✅ Gender (derived from ID)
- ✅ Address (住址)
- ✅ Nationality (民族)
- ✅ Issuing Authority (簽發機關)

**Example Card:**
```
姓名 Name:         王小明
性別 Sex:          男
民族 Nationality:  漢
出生 Date of Birth: 1990年1月1日
住址 Address:      四川省成都市...
公民身份號碼:       510623199001011234
```

---

### **3. Passport**

**Extracted Fields:**
- ✅ Surname
- ✅ Given Names
- ✅ Passport Number
- ✅ Nationality
- ✅ Date of Birth
- ✅ Sex
- ✅ Expiry Date
- ✅ Country Code

**Example Passport MRZ:**
```
P<CHNWANG<<XIAOMING<<<<<<<<<<<<<<<<<<<<<<<<
E12345678CHN9001015M3001017<<<<<<<<<<<<<<04
```

---

## 🔍 What Happens When You Scan

### **Behind the Scenes:**

```
1. Camera/Gallery → Image File
       ↓
2. OCR (ML Kit) → Raw Text
       ↓
3. Pattern Detection → ID Type
       ↓
4. AI API Call → Structured Data
       ↓
5. Display → User Interface
```

### **Detection Logic:**

The app automatically detects ID type by looking for patterns:

| Pattern Found | ID Type | AI Prompt Used |
|---------------|---------|----------------|
| `[A-Z]{1,2}\d{6}[0-9A]` | HKID | HKID extraction prompt |
| `\d{18}` | China ID | China ID extraction prompt |
| `P<...` (MRZ format) | Passport | Passport extraction prompt |

---

## 🛡️ Error Handling

### **If API Fails:**

The app **gracefully falls back** to basic parsing:

```
✓ Document Recognized (1 found)

HKID - Hong Kong ID Card
  ID Number:        M9259517      ← Still works!
  Letter Prefix:    M
  Digits:           925951
  Check Digit:      7
  Validation:       ✓ Valid
```

**You'll still get:**
- ✅ ID number extraction
- ✅ Checksum validation
- ✅ Basic fields

**You won't get:**
- ❌ Name
- ❌ Date of birth
- ❌ Date of issue
- ❌ Gender

### **Common Issues:**

| Issue | Cause | Solution |
|-------|-------|----------|
| "No text detected" | Blurry photo | Retake with better lighting |
| "No Document Found" | Unsupported ID | Check if ID type is supported |
| Basic fields only | API timeout | Check internet connection |
| Slow processing | Network delay | Wait or try again |

---

## 💡 Tips for Best Results

### **📸 Taking Good Photos:**

1. **Lighting:** Well-lit, no shadows
2. **Focus:** Sharp, not blurry
3. **Angle:** Straight-on, not tilted
4. **Distance:** Fill most of the frame
5. **Background:** Plain, contrasting

### **✅ Good Photo:**
```
┌─────────────────────────┐
│                         │
│   [=== ID CARD ===]    │  ← Clear, centered, well-lit
│                         │
└─────────────────────────┘
```

### **❌ Bad Photo:**
```
┌─────────────────────────┐
│  ╱                      │
│ ╱ [ID]  *shadow*       │  ← Tilted, blurry, shadowed
│╱                        │
└─────────────────────────┘
```

---

## 🎨 UI Features

### **Raw Text Section:**

Tap to expand/collapse:

```
📄 Scanned Text from ID Card
   12 lines detected
   ▼ (tap to expand)

   ┌─────────────────────────┐
   │ 香港特別行政區           │
   │ 姓名 Name CHAN TAI MAN  │
   │ 性別 Sex M              │
   │ ...                     │
   └─────────────────────────┘
```

### **Process Document Button:**

After scanning, you can:
```
[⚙️ Process Document]  ← Click to access additional features
```

This takes you to:
- CA Form Generation
- Digital Signature
- PDF Operations

---

## 🔧 Advanced Configuration

### **Disable AI (Optional):**

If you want to disable AI and use only basic parsing:

**In `lib/pages/id_ocr_full_feature_page.dart`:**

```dart
// Comment out AI service initialization
_idService = IdRecognitionService(
  ocrProvider: MlKitOcrAdapter(),
  // aiParserService: aiService, // ← Comment this out
);
```

### **Change API Endpoint (Optional):**

**In `lib/pages/id_ocr_full_feature_page.dart` (line 58):**

```dart
final aiService = AiParserService(
  apiUrl: 'https://your-new-api-url.com/api/chat',  // ← Change this
  apiKey: 'your-new-api-key',                        // ← Change this
);
```

### **Customize Prompts (Optional):**

**In `packages/id_ocr_kit/lib/services/ai_parser_service.dart`:**

Modify the `_buildHkidPrompt()`, `_buildChinaIdPrompt()`, or `_buildPassportPrompt()` methods to change what fields are extracted.

---

## 📊 Performance

### **Typical Times:**

| Operation | Duration |
|-----------|----------|
| Photo capture | < 1 second |
| OCR processing | 1-3 seconds |
| AI API call | 2-5 seconds |
| **Total** | **3-8 seconds** |

### **Network Requirements:**

- **Minimum:** 3G connection
- **Recommended:** 4G/LTE or WiFi
- **Offline:** Basic parsing only (no AI)

---

## ✅ Testing Checklist

### **HKID Test:**
- [ ] Chinese name extracted
- [ ] English name extracted
- [ ] Gender extracted
- [ ] Date of birth extracted
- [ ] Date of issue extracted
- [ ] ID number extracted and validated

### **China ID Test:**
- [ ] Chinese name extracted
- [ ] ID number extracted and validated
- [ ] Date of birth derived
- [ ] Gender derived
- [ ] Address extracted (if visible)

### **Passport Test:**
- [ ] Surname extracted
- [ ] Given names extracted
- [ ] Passport number extracted
- [ ] Nationality extracted
- [ ] Date of birth extracted
- [ ] Sex extracted
- [ ] Expiry date extracted

---

## 🆘 Troubleshooting

### **"No text detected"**

**Possible causes:**
- Photo is too dark
- Photo is blurry
- ID is not in frame

**Solutions:**
- Use flash or better lighting
- Hold phone steady
- Get closer to ID

---

### **"No Document Found"**

**Possible causes:**
- ID type not supported
- Text not recognized by OCR
- Photo quality too low

**Solutions:**
- Check if ID type is HKID, China ID, or Passport
- Retake photo with better quality
- Ensure ID text is visible

---

### **Only basic fields shown**

**Possible causes:**
- API is down or slow
- No internet connection
- API timeout

**Solutions:**
- Check internet connection
- Try again
- Wait for API to recover

**Note:** Basic parsing still works offline!

---

## 📞 Support

For issues or questions, check:
- `AI_PARSER_IMPLEMENTATION.md` - Technical details
- App logs - Look for error messages
- API documentation - Verify API format

---

## 🎉 Success!

You now have **AI-enhanced ID parsing** working in your app!

**What you get:**
- ✅ Automatic field extraction
- ✅ Structured data display
- ✅ No manual data entry needed
- ✅ Works with HKID, China ID, Passport
- ✅ Graceful error handling

**Enjoy your smart ID scanner! 🚀**

