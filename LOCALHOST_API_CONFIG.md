# Localhost API Configuration for Android Emulator

## ✅ **Changes Applied**

The API URL has been updated to use the Android emulator's special localhost alias.

---

## 📝 **Files Modified:**

### **1. `lib/pages/id_ocr_full_feature_page.dart`**

**Changed from:**
```dart
apiUrl: 'http://localhost:8006/api/chat',
```

**Changed to:**
```dart
apiUrl: 'http://10.0.2.2:8006/api/chat',  // Android emulator localhost alias
```

---

### **2. `lib/pages/additional_features_page.dart`**

**Changed from:**
```dart
apiUrl: 'http://localhost:8006/api/chat',
```

**Changed to:**
```dart
apiUrl: 'http://10.0.2.2:8006/api/chat',  // Android emulator localhost alias
```

---

### **3. `android/app/src/main/AndroidManifest.xml`**

**Added cleartext traffic permission:**
```xml
<application
    ...
    android:usesCleartextTraffic="true">  <!-- Added -->
```

**Why:** This allows HTTP (not HTTPS) connections, which is necessary for local development.

---

## 🎯 **What is 10.0.2.2?**

| Address | What It Means |
|---------|---------------|
| `localhost` in emulator | The emulator itself ❌ |
| `10.0.2.2` in emulator | Your host PC's localhost ✅ |

**Why we use it:**
- When you run an API on your PC at `http://localhost:8006`
- The Android emulator can't access it via `localhost`
- But it can access it via `http://10.0.2.2:8006`
- This is a special Android emulator feature

---

## 🚀 **How to Use:**

### **Step 1: Start Your Local API**

Make sure your API is running on your PC at port **8006**:

```bash
# Example (adjust based on your setup):
python app.py
# or
node server.js
# or
uvicorn main:app --host 0.0.0.0 --port 8006
```

**Verify it's running:**
- Open browser on your PC
- Go to `http://localhost:8006/api/chat`
- Should not show "connection refused"

---

### **Step 2: Run the Flutter App**

The app is already configured! Just run:

```bash
flutter run
```

The app will now connect to your local API running on port 8006.

---

### **Step 3: Test**

1. Click **"Scan ID"**
2. Capture or select an ID photo
3. Wait for OCR + AI processing
4. Check the terminal logs:

**Expected logs:**
```
INFO: AiParserService: Calling AI API...
INFO: AiParserService: API response status: 200
INFO: AiParserService: API call successful
INFO: AiParserService: Extracted 6 fields from China ID
```

---

## 🔍 **Troubleshooting:**

### **"Connection refused" Error**

```
SocketException: Connection refused
address = 10.0.2.2, port = 8006
```

**Possible causes:**
1. ❌ Your local API is not running
2. ❌ API is running on wrong port (not 8006)
3. ❌ Windows Firewall is blocking the connection

**Solutions:**
1. ✅ Start your API server
2. ✅ Check the port matches (8006)
3. ✅ Add firewall rule for port 8006

---

### **"Cleartext HTTP traffic not permitted"**

```
CLEARTEXT communication to 10.0.2.2 not permitted by network security policy
```

**Already fixed!** We added `android:usesCleartextTraffic="true"` to AndroidManifest.xml.

If you still see this, check that the change was applied correctly.

---

### **API Returns Wrong Data**

Make sure your local API:
- ✅ Accepts POST requests
- ✅ Expects `{"prompt": "..."}` parameter (not `"message"`)
- ✅ Returns JSON in format: `{"result": "{json data}"}`

---

## 🔄 **Switching Between Localhost and Production:**

### **For Local Development (Current Setup):**

```dart
apiUrl: 'http://10.0.2.2:8006/api/chat',
```

### **For Production/Azure API:**

```dart
apiUrl: 'https://amg-backend-dev-api3.azurewebsites.net/api/chat',
```

**To switch:**
1. Edit `id_ocr_full_feature_page.dart` (line ~62)
2. Edit `additional_features_page.dart` (line ~79)
3. Change the `apiUrl` value
4. Hot reload or restart the app

---

## 📱 **Using Physical Android Device:**

If you're using a real phone (not emulator):

1. **Find your PC's IP address:**
   ```bash
   ipconfig
   # Look for IPv4 Address: e.g., 192.168.1.100
   ```

2. **Update the URL:**
   ```dart
   apiUrl: 'http://192.168.1.100:8006/api/chat',  // Your PC's IP
   ```

3. **Make sure:**
   - Your phone is on the same Wi-Fi as your PC
   - Your firewall allows incoming connections on port 8006

---

## ✅ **Benefits of Local API:**

| Benefit | Description |
|---------|-------------|
| **Faster** | No internet latency |
| **Free** | No API costs during development |
| **Debuggable** | See API logs in real-time |
| **Works Offline** | No internet needed |
| **Better Control** | Modify API behavior instantly |

---

## 📊 **Expected Behavior:**

### **Before (with DNS error):**
```
❌ SocketException: Failed host lookup: 'amg-backend-dev-api3.azurewebsites.net'
WARNING: API call failed
INFO: Using basic parsing
```

**Result:** Only basic fields (ID number, checksum)

---

### **After (with localhost):**
```
✅ INFO: Calling AI API...
✅ INFO: API response status: 200
✅ INFO: Extracted 6 fields from China ID
✅ INFO: Enhanced China ID with 6 AI fields
```

**Result:** All fields including Chinese name, address, nationality!

---

## 🔧 **API Server Requirements:**

Your local API server should:

1. **Listen on port 8006:**
   ```python
   # Example with FastAPI/Uvicorn:
   uvicorn main:app --host 0.0.0.0 --port 8006
   ```

2. **Accept POST at `/api/chat`:**
   ```python
   @app.post("/api/chat")
   async def chat(request: dict):
       prompt = request.get("prompt")
       # Process prompt...
       return {"result": json.dumps(result_dict)}
   ```

3. **Return nested JSON format:**
   ```json
   {
     "result": "{\"chineseName\":\"...\",\"idNumber\":\"...\"}"
   }
   ```

---

## 🎉 **Summary:**

✅ **API URL updated** to `http://10.0.2.2:8006/api/chat`  
✅ **Cleartext HTTP enabled** in AndroidManifest.xml  
✅ **Both pages updated** (Scan ID + Additional Features)  
✅ **Ready to use** with local API server on port 8006

**Now test by scanning an ID card!** You should see AI-extracted fields like Chinese name, address, and nationality. 🚀

---

**Date:** December 4, 2025  
**Status:** ✅ Configured for local API at port 8006

