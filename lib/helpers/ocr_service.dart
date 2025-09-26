import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _imagePicker = ImagePicker();

  Future<Map<String, String>> pickAndProcessImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image == null) return {};

    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    return _parseTextForAmount(recognizedText.text);
  }

  Map<String, String> _parseTextForAmount(String text) {
    // This is a simple parsing logic. It can be greatly improved.
    // It looks for keywords like "total", "amount" and then finds the largest number nearby.
    final lines = text.toLowerCase().split('\n');
    double largestAmount = 0.0;
    
    // First, try to find a line with "total" or a similar keyword
    for(final line in lines) {
      if(line.contains('total') || line.contains('amount') || line.contains('balance')) {
        final words = line.replaceAll(',', '').split(' ');
        for (final word in words) {
          final amount = double.tryParse(word);
          if (amount != null && amount > largestAmount) {
            largestAmount = amount;
          }
        }
      }
    }

    // If no total found, just take the largest number in the whole text as a fallback
    if (largestAmount == 0.0) {
      // This regex is better for finding numbers with decimal points
      RegExp regExp = RegExp(r"(\d{1,3}(,\d{3})*(\.\d+)?|\d+(\.\d+)?)");
      var matches = regExp.allMatches(text);
      for(final match in matches){
        final amount = double.tryParse(match.group(0)!.replaceAll(',', ''));
        if(amount != null && amount > largestAmount){
          largestAmount = amount;
        }
      }
    }

    return {
      'amount': largestAmount > 0.0 ? largestAmount.toStringAsFixed(2) : '',
      'description': lines.isNotEmpty ? lines.first.toUpperCase() : 'Scanned Receipt',
    };
  }
}