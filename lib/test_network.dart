import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

/// Simple network test page to diagnose connectivity issues
class TestNetworkPage extends StatefulWidget {
  const TestNetworkPage({super.key});

  @override
  State<TestNetworkPage> createState() => _TestNetworkPageState();
}

class _TestNetworkPageState extends State<TestNetworkPage> {
  String _status = 'Tap button to test network';
  bool _testing = false;

  Future<void> _testNetwork() async {
    setState(() {
      _testing = true;
      _status = 'Testing network connectivity...\n\n';
    });

    final results = <String>[];

    // Test 1: DNS Resolution
    try {
      results.add('🔍 Test 1: DNS Resolution');
      final addresses = await InternetAddress.lookup('google.com');
      results.add('✅ DNS works! Resolved google.com to: ${addresses.first.address}\n');
    } catch (e) {
      results.add('❌ DNS failed: $e\n');
    }

    // Test 2: HTTP to Google
    try {
      results.add('🌐 Test 2: HTTP to Google');
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(
        const Duration(seconds: 10),
      );
      results.add('✅ HTTP works! Status: ${response.statusCode}\n');
    } catch (e) {
      results.add('❌ HTTP failed: $e\n');
    }

    // Test 3: HTTP to your API
    try {
      results.add('🔌 Test 3: Your API Endpoint');
      final response = await http.get(
        Uri.parse('https://amg-backend-dev-api3.azurewebsites.net/'),
      ).timeout(const Duration(seconds: 10));
      results.add('✅ API reachable! Status: ${response.statusCode}\n');
    } catch (e) {
      results.add('❌ API unreachable: $e\n');
    }

    // Test 4: DNS for your API
    try {
      results.add('🔍 Test 4: DNS for Your API Domain');
      final addresses = await InternetAddress.lookup('amg-backend-dev-api3.azurewebsites.net');
      results.add('✅ API DNS works! Resolved to: ${addresses.first.address}\n');
    } catch (e) {
      results.add('❌ API DNS failed: $e\n');
    }

    setState(() {
      _status = results.join('\n');
      _testing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _testing ? null : _testNetwork,
              icon: _testing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.wifi_find),
              label: const Text('Test Network Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _status,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

