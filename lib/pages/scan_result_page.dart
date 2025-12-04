import 'package:flutter/material.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';

/// Result page showing "Identity has been checked" after OCR scan
/// Part of the Test Figma / ID Scanner feature
class ScanResultPage extends StatelessWidget {
  final IdRecognitionResult result;

  const ScanResultPage({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Scan Result'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3F5AA6),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green.shade600,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // "Identity has been checked" title
              Text(
                'Identity has been checked',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Result cards
              ..._buildResultCards(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResultCards(BuildContext context) {
    final cards = <Widget>[];
    
    if (result.parsedIds != null && result.parsedIds!.isNotEmpty) {
      for (var idResult in result.parsedIds!) {
        cards.add(_buildResultCard(context, idResult));
        cards.add(const SizedBox(height: 16));
      }
    } else {
      // No IDs found
      cards.add(_buildEmptyCard(context));
    }
    
    return cards;
  }

  Widget _buildResultCard(BuildContext context, IdParseResult idResult) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID Type
            Row(
              children: [
                Icon(
                  _getIconForType(idResult),
                  color: const Color(0xFF3F5AA6),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    idResult.type,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3F5AA6),
                    ),
                  ),
                ),
                // Validation badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: idResult.isValid 
                        ? Colors.green.shade50 
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: idResult.isValid 
                          ? Colors.green.shade300 
                          : Colors.red.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        idResult.isValid 
                            ? Icons.check_circle 
                            : Icons.error,
                        size: 16,
                        color: idResult.isValid 
                            ? Colors.green.shade700 
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        idResult.isValid ? 'Valid' : 'Invalid',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: idResult.isValid 
                              ? Colors.green.shade700 
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            // ID Details
            ..._buildIdDetails(context, idResult),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No ID detected',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again with a clearer image',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIdDetails(BuildContext context, IdParseResult idResult) {
    final details = <Widget>[];
    
    // Display all fields from the parsed result
    idResult.fields.forEach((key, value) {
      details.add(_buildDetailRow(key, value, _getIconForField(key)));
    });
    
    if (details.isEmpty) {
      details.add(
        _buildDetailRow('Status', 'Document scanned', Icons.description),
      );
    }
    
    return details;
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(IdParseResult idResult) {
    if (idResult is HkidResult) return Icons.credit_card;
    if (idResult is ChinaIdResult) return Icons.credit_card;
    if (idResult is PassportResult) return Icons.book;
    return Icons.description;
  }

  IconData _getIconForField(String fieldName) {
    final lower = fieldName.toLowerCase();
    
    if (lower.contains('id') || lower.contains('number') || lower.contains('passport')) {
      return Icons.badge;
    }
    if (lower.contains('name') || lower.contains('surname') || lower.contains('given')) {
      return Icons.person;
    }
    if (lower.contains('birth') || lower.contains('dob')) {
      return Icons.cake;
    }
    if (lower.contains('gender') || lower.contains('sex')) {
      return Icons.people;
    }
    if (lower.contains('expiry') || lower.contains('date')) {
      return Icons.event;
    }
    if (lower.contains('nationality') || lower.contains('country')) {
      return Icons.flag;
    }
    if (lower.contains('valid')) {
      return Icons.verified_user;
    }
    
    return Icons.info;
  }
}
