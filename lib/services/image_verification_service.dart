// import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
//
// class ImageVerificationService {
//   // Keywords that represent real nature/agriculture
//   static final List<String> _agricultureKeywords = [
//     'Plant', 'Leaf', 'Crop', 'Agriculture', 'Vegetable', 'Fruit', 'Tree',
//     'Flower', 'Botany', 'Herb', 'Grass', 'Nature', 'Field', 'Greenery',
//     'Terrestrial plant', 'Vascular plant', 'Plant stem'
//   ];
//
//   // Keywords that represent screenshots, humans, or indoor objects
//   static final List<String> _forbiddenKeywords = [
//     // Digital/Screenshots
//     'Screenshot', 'Text', 'Font', 'Graphic design', 'Logo', 'Icon', 'Brand',
//     'Software', 'Web page', 'User interface', 'Number', 'Website', 'Application',
//     'Multimedia', 'Advertising', 'Computer', 'Laptop', 'Screen', 'Display',
//     // Humans
//     'Person', 'Human', 'Face', 'Man', 'Woman', 'Child', 'Selfie', 'Clothing',
//     // Indoor/Other
//     'Room', 'Furniture', 'Table', 'Chair', 'Building', 'House', 'Indoor',
//     'Electronics', 'Home appliance', 'Vehicle', 'Car'
//   ];
//
//   static Future<bool> isCropImage(String filePath) async {
//     final inputImage = InputImage.fromFilePath(filePath);
//     // Lower threshold to catch even faint UI/Human elements
//     final imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.4));
//
//     try {
//       final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
//
//       if (labels.isEmpty) return false;
//
//       double plantConfidence = 0.0;
//       bool isForbidden = false;
//       String detectedForbidden = '';
//
//       print('--- VERIFICATION SCAN START ---');
//       for (ImageLabel label in labels) {
//         String text = label.label.toLowerCase();
//         double conf = label.confidence;
//         print('Detected: $text (${conf.toStringAsFixed(2)})');
//
//         // 1. Check for Forbidden elements (Digital, Human, etc.)
//         // If we see UI/Screenshot elements with > 40% confidence, we reject.
//         if (_forbiddenKeywords.any((k) => text.contains(k.toLowerCase()))) {
//           if (conf > 0.4) {
//             isForbidden = true;
//             detectedForbidden = text;
//           }
//         }
//
//         // 2. Aggregate Plant confidence
//         if (_agricultureKeywords.any((k) => text.contains(k.toLowerCase()))) {
//           if (conf > plantConfidence) plantConfidence = conf;
//         }
//       }
//       print('--- SCAN END. Plant Conf: $plantConfidence, Forbidden: $isForbidden ($detectedForbidden) ---');
//
//       // DECISION:
//       // - Must have a plant with > 60% confidence
//       // - Must NOT have any forbidden element (screenshot/human) detected.
//       bool isAccepted = (plantConfidence > 0.6) && !isForbidden;
//
//       print('RESULT: ${isAccepted ? "ACCEPTED" : "REJECTED"}');
//       return isAccepted;
//
//     } catch (e) {
//       print('VERIFICATION ERROR: $e');
//       return false;
//     } finally {
//       imageLabeler.close();
//     }
//   }
// }
