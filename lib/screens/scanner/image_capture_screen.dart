import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';
import '../../config/api_config.dart';

class ImageCaptureScreen extends StatefulWidget {
  final Function(Map<String, String>) onImageCaptured;

  const ImageCaptureScreen({required this.onImageCaptured, super.key});

  @override
  State<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _captureAndProcessImage() async {
    try {
      setState(() => _isProcessing = true);

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      Map<String, String>? result;
      if (ApiConfig.isClaudeVisionEnabled) {
        result = await _extractWithClaudeVision(image.path);
      }

      result ??= await _extractWithMlKit(image.path);

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        widget.onImageCaptured(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isProcessing = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    Map<String, String>? result;
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() => _isProcessing = true);
      if (ApiConfig.isClaudeVisionEnabled) {
        result = await _extractWithClaudeVision(image.path);
      }
      result ??= await _extractWithMlKit(image.path);
    } catch (e) {
      result = null;
    }
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (result != null) {
      Navigator.pop(context);
      widget.onImageCaptured(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not process image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, String>?> _extractWithClaudeVision(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final ext = imagePath.split('.').last.toLowerCase();
      final mediaType = ext == 'png' ? 'image/png' : 'image/jpeg';

      final response = await http.post(
        Uri.parse(ApiConfig.anthropicEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ApiConfig.anthropicApiKey,
          'anthropic-version': ApiConfig.anthropicVersion,
        },
        body: jsonEncode({
          'model': ApiConfig.claudeModel,
          'max_tokens': 256,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': '''You are a grocery price tag reader for a Philippine supermarket app.

Look at this image carefully. It may be a:
- Printed supermarket shelf label
- Handwritten price tag
- Digital/LCD price display
- Thermal receipt

Extract ONLY:
1. The product name (the item being sold, not the store name)
2. The price in Philippine Peso (PHP)

Rules:
- Product name: be specific, include brand and variant if visible (e.g. "Alaska Evaporated Milk 370ml" not just "Milk")
- Price: numeric value only, no currency symbols (e.g. "85.00" not "P85.00")
- If you see multiple prices (original + sale), use the SALE/CURRENT price
- If you cannot clearly read the name or price, use "unknown"

Respond ONLY with valid JSON, no explanation:
{"name": "product name here", "price": "00.00"}'''
                }
              ]
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'] as List?;
        if (content == null || content.isEmpty) return null;

        final textBlock = content.cast<Map<String, dynamic>>().where(
          (block) => block['type'] == 'text' && block['text'] != null,
        );
        if (textBlock.isEmpty) return null;

        final text = textBlock.first['text'] as String;

        final clean = text
            .replaceAll(RegExp(r'```json|```'), '')
            .trim();

        final parsed = jsonDecode(clean) as Map<String, dynamic>;
        final name = (parsed['name'] as String?)?.trim() ?? '';
        final price = (parsed['price'] as String?)?.trim() ?? '';

        if (name.isNotEmpty &&
            name.toLowerCase() != 'unknown' &&
            price.isNotEmpty &&
            price != '0' &&
            price.toLowerCase() != 'unknown') {
          return {
            'name': name,
            'price': price,
            '_source': 'claude_vision',
            '_debug_text': 'Extracted by Claude Vision API',
          };
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _extractWithMlKit(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      String fullText = recognizedText.text;
      List<String> allLines = [];

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          allLines.add(line.text);
        }
      }

      final result = _extractPriceAndName(fullText, allLines);
      result['_source'] = 'mlkit_fallback';
      result['_debug_text'] = fullText;

      return result;
    } finally {
      await textRecognizer.close();
    }
  }

  Map<String, String> _extractPriceAndName(
    String text, [
    List<String>? structuredLines,
  ]) {
    final lines = structuredLines ?? text.split('\n');
    final cleanLines = lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? extractedPrice;

    bool isValidPrice(double val) => val >= 5.0 && val <= 50000.0;

    String normalizeDecimal(String s) => s.replaceAll(',', '.');

    final p1 = RegExp(r'[?P]\s*([\d,]{1,7}\.\d{2})', caseSensitive: false);

    final p2 = RegExp(
      r'(?:price|presyo|amount|total|subtotal|halaga)[\s:]*[?P]?\s*([\d,]{1,7}(?:\.\d{2})?)',
      caseSensitive: false,
    );

    final p3 = RegExp(r'[?P]\s*(\d{1,6})(?!\d|\.)', caseSensitive: false);

    final p4 = RegExp(
      r'(\d{1,6}(?:\.\d{2})?)\s*(?:pesos?|php)',
      caseSensitive: false,
    );

    final p5 = RegExp(r'\b(\d{1,4}\.\d{2})\b');

    for (final pattern in [p1, p2, p3, p4, p5]) {
      for (final line in cleanLines) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final raw = normalizeDecimal(match.group(1)!.replaceAll(',', ''));
          final val = double.tryParse(raw);
          if (val != null && isValidPrice(val)) {
            extractedPrice = val.toStringAsFixed(2);
            break;
          }
        }
      }
      if (extractedPrice != null) break;
    }

    const skipKeywords = [
      'puregold', 'sm supermarket', 'sm market', 'sm hypermarket',
      'robinsons', 'landers', 'savemore', 'waltermart', 'shopwise',
      'alfamart', 'ministop', '7-eleven', 'family mart', 'lawson',
      'hypermarket', 'supermarket', 'palengke', 'bonus', 'quality products',
      'price', 'presyo', 'amount', 'total', 'subtotal', 'change',
      'cash', 'thank you', 'receipt', 'resibo', 'date', 'time',
      'cashier', 'tin', 'vat', 'tax', 'discount', 'sale', 'promo',
      'member', 'card', 'branch', 'store', 'address', 'tel',
      'phone', 'website', 'www', 'transaction', 'ref no',
      'etvwt', 'net wt', 'netwt', 'sku', 'item code', 'barcode',
    ];

    const productWords = [
      'milk', 'bread', 'rice', 'egg', 'eggs', 'chicken', 'pork', 'beef',
      'fish', 'oil', 'sugar', 'salt', 'coffee', 'tea', 'juice', 'water',
      'butter', 'cheese', 'flour', 'vinegar', 'sauce', 'noodles', 'pasta',
      'tuna', 'sardines', 'canned', 'frozen', 'fresh', 'organic',
      'instant', 'dried', 'powder', 'condensed', 'evaporated',
      'shampoo', 'soap', 'detergent', 'lotion', 'toothpaste',
      'gelatine', 'gelatin', 'jelly', 'dessert', 'pudding',
      'bawang', 'sibuyas', 'kamatis', 'gata', 'bagoong', 'patis',
      'suka', 'toyo', 'asin', 'asukal', 'bigas', 'itlog', 'manok',
      'baboy', 'baka', 'isda', 'bangus', 'tilapia', 'galunggong',
      'liempo', 'lechon', 'longganisa', 'tocino', 'tapa',
      'pandesal', 'hopia', 'polvoron', 'bibingka', 'gulaman',
      'datu', 'century', 'del monte', 'ufc', 'mama sita', 'mamasita',
      'ajinomoto', 'maggi', 'knorr', 'lucky me', 'payless', 'monde',
      'rebisco', 'fita', 'skyflakes', 'milo', 'nescafe', 'kopiko',
      'bear brand', 'alaska', 'magnolia', 'selecta', 'nestea',
      'c2', 'zesto', 'grande', 'sunquick', 'tang',
      'ariel', 'tide', 'surf', 'champion', 'joy', 'domex',
      'safeguard', 'palmolive', 'head shoulders', 'pantene',
      'colgate', 'closeup', 'hapee', 'ferna', 'sarappinoy',
    ];

    final barcodePattern = RegExp(r'\d{12,}');
    final datePattern = RegExp(r'\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}');
    final pureDigitPattern = RegExp(r'^\d+$');
    final priceOnlyPattern = RegExp(r'^[?P\d\s.,]+$');
    final codePattern = RegExp(r'^[A-Z]{2,}\s*[.\s]*\s*\d+$', caseSensitive: false);

    String? bestName;
    int bestScore = -999;

    for (final line in cleanLines) {
      final lower = line.toLowerCase();

      if (line.length < 3) continue;
      if (barcodePattern.hasMatch(line)) continue;
      if (pureDigitPattern.hasMatch(line)) continue;
      if (priceOnlyPattern.hasMatch(line)) continue;
      if (datePattern.hasMatch(line)) continue;
      if (codePattern.hasMatch(line)) continue;
      if (skipKeywords.any((kw) => lower.contains(kw))) continue;

      final digitCount = line.replaceAll(RegExp(r'[^\d]'), '').length;
      if (line.isNotEmpty && digitCount / line.length > 0.6) continue;

      if (RegExp(r'^\d+[a-z]*$', caseSensitive: false).hasMatch(line)) continue;

      int score = 0;

      if (RegExp(
        r'\b(\d+\s*(?:g|kg|ml|l|oz|lb|pcs|pc|pack|sachet|pouch|can|bottle|box|grams?|liters?|kilos?))\b',
        caseSensitive: false,
      ).hasMatch(line)) {
        score += 15;
      }

      if (RegExp(r'[A-Z][a-z]+').hasMatch(line)) score += 5;

      if (line.length >= 8 && line.length <= 60) score += 5;
      if (line.length < 8) score -= 3;
      if (line.length > 80) score -= 5;

      if (productWords.any((w) => lower.contains(w))) score += 10;

      if (line == line.toUpperCase() && line.length < 20) score -= 3;

      if (line.contains('.') && !priceOnlyPattern.hasMatch(line)) score += 2;

      if (RegExp(r'^[A-Z]').hasMatch(line)) score += 3;

      if (lower.contains('ferna') || lower.contains('sarappinoy')) score += 15;

      if (score > bestScore) {
        bestScore = score;
        bestName = line;
      }
    }

    if (bestName != null) {
      bestName = bestName
          .replaceAll(RegExp(r'\s*[?P]\s*\d+[.,]?\d*\s*$'), '')
          .replaceAll(RegExp(r'\s*\d+\.\d{2}\s*$'), '')
          .replaceAll(RegExp(r'^[^\w?]+|[^\w?]+$'), '')
          .trim();

      if (bestName.isEmpty) bestName = null;
    }

    return {
      'name': bestName ?? 'Unknown Product',
      'price': extractedPrice ?? '0',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Capture Price Tag'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_isProcessing ? Icons.hourglass_empty : Icons.help_outline),
            onPressed: _isProcessing ? null : () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('Tips'),
                    ],
                  ),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('For best results:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('? Use good lighting'),
                        Text('? Hold phone steady'),
                        Text('? Fill frame with price tag'),
                        Text('? Keep text straight'),
                        Text('? Tap to focus'),
                        SizedBox(height: 12),
                        Text('Avoid:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('? Blurry photos'),
                        Text('? Shadows or glare'),
                        Text('? Tilted angles'),
                        Text('? Low light'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryGreen),
                  const SizedBox(height: 24),
                  Text(
                    'Processing image...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Extracting text with AI',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Capture Price Tag',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Text(
                          'Take a photo of the price tag to automatically extract product name and price',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Tap ? for tips on best results',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: _captureAndProcessImage,
                    icon: const Icon(Icons.camera),
                    label: const Text('Open Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _pickFromGallery(),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                ],
              ),
      ),
    );
  }
}
