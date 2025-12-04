# PDF Field Visualizer Guide 📊

## 🎯 What is PDF Field Visualizer?

PDF Field Visualizer creates a labeled copy of your PDF where **each field is filled with its own internal name**. This makes it incredibly easy to see which internal field name corresponds to which visible field in your PDF form.

---

## ✨ Features

### **Automatic Field Labeling**
- ✏️ **Auto-fills** each field with its own internal name
- 📄 **Creates new PDF** - Original stays unchanged
- 💾 **Saves to Downloads** - Easy to find and share
- 📱 **Auto-opens** - Opens labeled PDF automatically

### **What You Get**
- 🏷️ Every text field shows its internal name (e.g., "Name", "IdNo", "Mobile")
- 📋 Perfect reference for form development
- 💯 100% accurate field mapping
- 🔄 Can regenerate anytime with timestamp

---

## 🚀 How to Use

### **Step 1: Select PDF**
1. Open your app
2. Find the "PDF Inspector (Debug)" section
3. Use the dropdown to select either:
   - MINA PDF
   - CA3 PDF

### **Step 2: Create Labeled PDF**
1. Click the purple **"Visualize PDF Fields"** button
2. Wait a moment while PDF is being processed
3. A new PDF will be created and opened automatically

### **Step 3: View the Labeled PDF**
- Each text field now displays its own internal name
- Example: The "客戶姓名" field will show "Name"
- Example: The "身份證號碼" field will show "IdNo"
- Example: The "手機號碼" field will show "Mobile"

### **Step 4: Document Your Findings**
As you see each field's internal name, record the mapping:

```
Visual Label → Internal Field Name

Example for CA3 PDF:
- "Name of First Client" → Name
- "ID Number" → IdNo  
- "Mobile Number" → Mobile
- "Email Address" → EmailAddress
- "Client Signature" → ClientSign
```

---

## 🎨 Understanding the Labeled PDF

### **What You'll See**

When you open the labeled PDF, each field will display its own internal name:

```
CA3 表單範例:

┌────────────────────────────────────┐
│ Individual Client 個人客戶          │
├────────────────────────────────────┤
│                                     │
│ Name of First client: ┌──────────┐ │
│                       │   Name   │ │ ← 顯示字段名稱！
│                       └──────────┘ │
│                                     │
│ ID Number:           ┌──────────┐  │
│                      │   IdNo   │  │ ← 顯示字段名稱！
│                      └──────────┘  │
│                                     │
│ Mobile:              ┌──────────┐  │
│                      │  Mobile  │  │ ← 顯示字段名稱！
│                      └──────────┘  │
│                                     │
│ Email:               ┌─────────────┐│
│                      │EmailAddress││ ← 顯示字段名稱！
│                      └─────────────┘│
│                                     │
│ [Signature Section]                │
│ Client Signature:  ┌────────────┐  │
│                    │ ClientSign │  │ ← 顯示字段名稱！
│                    └────────────┘  │
└────────────────────────────────────┘
```

### **File Naming**

Created PDF follows this pattern:
```
Original: CA 3.pdf
Labeled:  CA 3_LABELED_1732788451234.pdf
          └─────┘ └─────┘ └─────────┘
          Name    Suffix   Timestamp
```

### **Storage Location**

- **Android**: `/storage/emulated/0/Download/`
- **Other platforms**: App's temporary directory
- **File stays permanently** - Use as reference anytime

---

## 💡 Tips for Field Mapping

### **Tip 1: Open in PDF Reader**
The labeled PDF opens in your device's default PDF reader:
- Use zoom to see small fields clearly
- Navigate pages freely
- Take screenshots for reference
- Share with team members

### **Tip 2: Work Section by Section**
Map fields by form section:
1. Personal Information section
2. Contact Information section
3. Address section
4. Signature section

### **Tip 3: Keep the File**
The labeled PDF is saved permanently:
- Use as reference document
- Share with developers
- Print for physical reference
- No need to recreate each time

### **Tip 4: Cross-Reference with Inspector**
For detailed position info:
1. Use "Inspect Form Fields" button first
2. Check console for coordinates
3. Then use "Visualize PDF Fields" to confirm

---

## 📝 Creating Your Mapping Document

### **Template**

```markdown
## CA3 PDF Field Mapping

### Page 1 - Client Information
| Visual Label | Field Name | Location |
|-------------|------------|----------|
| Full Name | Name | Top Left |
| ID Number | IdNo | Below Name |
| Mobile Phone | Mobile | Middle Left |
| Home Phone | Home | Middle Left |
| Office Phone | Office | Middle Left |
| Email | EmailAddress | Middle Left |
| Home Address Line 1 | Residential1 | Middle |
| Home Address Line 2 | Residential2 | Middle |
| Home Address Line 3 | Residential3 | Middle |
| Correspondence Address 1 | Correspondence1 | Right |
| Correspondence Address 2 | Correspondence2 | Right |
| Correspondence Address 3 | Correspondence3 | Right |

### Page 2 - Signatures
| Visual Label | Field Name | Location |
|-------------|------------|----------|
| Client Name | Name | Bottom Left |
| Client Signature | ClientSign | Bottom Left |
| Date | TextField19 | Bottom Left |
| Adviser Name | AdviserName | Bottom Right |
| Adviser Signature | AdviserSign | Bottom Right |
| License Number | LicenceNo | Bottom Right |
```

---

## 🎯 Use Cases

### **1. Form Filling Development**
When coding form filling logic:
```dart
// Now you know the exact field names!
await pdfAdapter.fillTextField(
  document: pdfDoc,
  fieldName: 'Name',  // ← Found with visualizer
  value: clientName,
);
```

### **2. Data Migration**
Mapping old system fields to new PDF fields:
- Old DB: `client_full_name` → PDF: `Name`
- Old DB: `id_card_no` → PDF: `IdNo`

### **3. Testing & QA**
Verify all fields are populated correctly:
- Check each visible field has correct data
- Compare against field name list

### **4. Team Documentation**
Share the mapping with:
- Developers
- QA testers  
- Product managers
- Business analysts

---

## 🐛 Troubleshooting

### **Problem: Labels are overlapping**
**Solution:**
- Zoom in to see details
- Toggle labels off temporarily
- Check the bottom scroll list

### **Problem: Can't see some fields**
**Solution:**
- Make sure you're on the right page
- Scroll to different parts of the PDF
- Check if fields are on other pages

### **Problem: Coordinates seem wrong**
**Note:** The overlay uses simplified coordinate mapping. For precise coordinates, refer to the "Inspect Form Fields" console output.

### **Problem: PDF loads but no fields shown**
**Possible causes:**
- PDF has no form fields (is not a fillable form)
- Fields have no names
- Check console for loading errors

---

## 🎨 Customization (For Developers)

### **Change Field Colors**

In `pdf_field_visualizer_page.dart`:

```dart
// Border color
final borderPaint = Paint()
  ..color = Colors.blue.withOpacity(0.6)  // ← Change this
  
// Background color  
final bgPaint = Paint()
  ..color = Colors.blue.withOpacity(0.1)  // ← Change this
  
// Label background
Paint()..color = Colors.blue.withOpacity(0.9)  // ← Change this
```

### **Change Label Size**

```dart
style: const TextStyle(
  fontSize: 10,  // ← Change this
  fontWeight: FontWeight.bold,
),
```

---

## 📊 Comparison with Other Methods

| Method | Speed | Accuracy | Ease of Use |
|--------|-------|----------|-------------|
| **Visual Overlay** | ⚡⚡⚡ Fast | ✅ Perfect | 😊 Very Easy |
| Coordinate Matching | ⏱️ Slow | ⚠️ Approximate | 😓 Difficult |
| Console Only | ⏱️ Medium | ✅ Perfect | 😐 Moderate |
| Trial & Error | 🐌 Very Slow | ❌ Error-prone | 😫 Frustrating |

---

## ✅ Workflow Summary

```
1. Open App
   ↓
2. Select PDF (MINA or CA3)
   ↓
3. Click "Visualize PDF Fields"
   ↓
4. See field names overlaid on PDF
   ↓
5. Navigate through pages
   ↓
6. Record field name → visible label mapping
   ↓
7. Use mapping in your form filling code
   ↓
8. Test and verify ✅
```

---

## 🎉 Benefits

✅ **Visual** - See exactly where each field is  
✅ **Fast** - Map all fields in minutes  
✅ **Accurate** - No guessing required  
✅ **Interactive** - Zoom, scroll, toggle  
✅ **Complete** - Shows all fields at once  
✅ **Easy** - No technical knowledge needed  
✅ **Shareable** - Create documentation easily  

---

## 📞 Quick Reference

### **Buttons**
- 👁️ Toggle Labels - Show/hide field overlays
- ℹ️ Statistics - Field count and zoom info
- ← Back - Return to main screen

### **Gestures**
- Swipe - Change pages
- Pinch - Zoom in/out
- Scroll - Move around PDF

### **Bottom Bar**
- Horizontal scroll - View all fields on current page
- Each card - Shows field name and position

---

## 🚀 Next Steps

After using the visualizer:

1. ✅ Document your field mappings
2. ✅ Update your form filling code
3. ✅ Test with real data
4. ✅ Share mapping with team
5. ✅ Keep mapping as reference document

Happy mapping! 🎊

---

## 💾 Save This Mapping!

Don't lose your work - save your field mapping document to:
- Team wiki
- Project documentation
- Code comments
- README file

This will save hours of work for future developers!

