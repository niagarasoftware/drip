import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/crop_advisory_web_sidebar.dart';
import 'package:oro_drip_irrigation/cropAdvisory/view/field_information_screen.dart';
import 'package:path_provider/path_provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../services/ai_service.dart';
import '../../services/image_verification_service.dart';
import '../helper/image_compressor.dart';
import '../model/cropadvisory_model.dart';
import 'package:http/http.dart' as http;

import '../widgets/AppTextField.dart';
import '../widgets/ContinueButton.dart';
import '../widgets/ProgressWidget.dart';
import '../widgets/SectionCard.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CropDetailsScreen extends StatefulWidget {
  const CropDetailsScreen({super.key, required this.cropId, required this.edit, this.userId, this.controllerId} );
  final cropId,userId,controllerId;
  final bool edit;
  @override
  State<CropDetailsScreen> createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends State<CropDetailsScreen> {
  final TextEditingController _cropNameController = TextEditingController();
  final TextEditingController _varietyController = TextEditingController();
  final TextEditingController _plantingDateController = TextEditingController();
  final TextEditingController _harvestDateController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _arrangementController = TextEditingController();
  final TextEditingController _cropTypeController = TextEditingController();

  final FocusNode _cropNameFocusNode = FocusNode();
  final FocusNode _varietyFocusNode = FocusNode();
  final FocusNode _durationFocusNode = FocusNode();
  final FocusNode _arrangementFocusNode = FocusNode();
  final FocusNode _cropTypeFocusNode = FocusNode();

  String _plantingMethod = 'Sowing';
  final CropAdvisoryModel _model = CropAdvisoryModel.instance;
  File? cropImage;
  final ImagePicker _picker = ImagePicker();
  Uint8List? webImage;

  final List<String> _cropNameSuggestions = [
    'Cotton', 'Sugarcane', 'Maize', 'Groundnut', 'Wheat', 'Tomato', 'Chilli', 
    'Brinjal', 'Okra', 'Cabbage', 'Cauliflower', 'Cucumber', 'Capsicum', 
    'Pumpkin', 'Bitter Gourd', 'Banana', 'Pomegranate', 'Papaya', 'Grapes', 
    'Mango', 'Guava', 'Sweet Lime', 'Orange', 'Watermelon', 'Muskmelon', 
    'Turmeric', 'Ginger', 'Aloe Vera', 'Ashwagandha', 'Tulsi', 'Coconut', 
    'Arecanut', 'Coffee', 'Tea', 'Rubber'
  ];

  final List<String> _varietySuggestions = [
    'Traditional (Local) varieties',
    'Improved varieties',
    'Hybrid varieties',
    'High-yielding varieties (HYVs)',
    'Disease-resistant varieties',
    'Drought-tolerant varieties',
    'Open-pollinated varieties (OPVs)',
    'Organic seeds',
    'Genetically Modified (GMO) seeds',
  ];

  final List<String> _arrangementSuggestions = [
    'Formal rows',
    'Staggered rows',
    'Mass planting',
    'Border planting',
    'Layered planting',
    'Cluster planting',
    'Mixed planting',
    'Container grouping',
    'Line arrangement',
    'Mass arrangement',
    'Line-mass arrangement',
    'Triangular arrangement',
    'Circular arrangement',
    'Crescent arrangement',
    'Ikebana style',
  ];

  final List<String> _durationSuggestions = [
    'Short term (< 3 months)',
    'Medium term (3-6 months)',
    'Long term (> 6 months)',
    'Annual',
    'Biennial',
    'Perennial',
  ];

  final List<String> _cropTypeSuggestions = [
    'Open-field cultivation',
    'Greenhouse / Polyhouse cultivation',
    'Hydroponics / Soilless cultivation',
    'Aeroponics',
    'Orchard / Plantation',
    'Protected cultivation',
    'Container Gardening',
  ];

  Widget _buildInlineSuggestions({
    required FocusNode focusNode,
    required TextEditingController controller,
    required List<String> suggestions,
  }) {
    if (!focusNode.hasFocus) return const SizedBox.shrink();
    
    final query = controller.text.toLowerCase();
    final filtered = suggestions.where((item) => item.toLowerCase().contains(query)).toList();
    
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              setState(() {
                controller.text = item;
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: item.length),
                );
              });
              // Unfocus after a tiny delay to ensure input registers
              Future.microtask(() => focusNode.unfocus());
            },
            child: ListTile(
              title: Text(item),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill fields from singleton instance if they have values
    _cropNameController.text = _model.cropName ?? '';
    _varietyController.text = _model.cropVariety ?? '';
    _plantingDateController.text = _model.plantingDate ?? '';
    _harvestDateController.text = _model.expectedHarvestDate ?? '';
    _durationController.text = _model.cropDuration ?? '';
    _arrangementController.text = _model.plantArrangement ?? '';
    _cropTypeController.text = _model.cropType ?? '';
    if (_model.plantingMethod != null) {
      _plantingMethod = _model.plantingMethod!;
    }

    _cropNameFocusNode.addListener(() => setState(() {}));
    _varietyFocusNode.addListener(() => setState(() {}));
    _durationFocusNode.addListener(() => setState(() {}));
    _arrangementFocusNode.addListener(() => setState(() {}));
    _cropTypeFocusNode.addListener(() => setState(() {}));

    _cropNameController.addListener(() => setState(() {}));
    _varietyController.addListener(() => setState(() {}));
    _durationController.addListener(() => setState(() {}));
    _arrangementController.addListener(() => setState(() {}));
    _cropTypeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _varietyController.dispose();
    _plantingDateController.dispose();
    _harvestDateController.dispose();
    _durationController.dispose();
    _arrangementController.dispose();
    _cropTypeController.dispose();
    _cropNameFocusNode.dispose();
    _varietyFocusNode.dispose();
    _durationFocusNode.dispose();
    _arrangementFocusNode.dispose();
    _cropTypeFocusNode.dispose();
    super.dispose();
  }

  Widget buildMethodButton(String title) {
    bool isSelected = _plantingMethod == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _plantingMethod = title;
          });
        },
        child: Container(
          height: 55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff0E8797).withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isSelected
                    ? const Color(0xff0E8797)
                    : Colors.grey.shade300),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? const Color(0xff0E8797) : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openCamera() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [

              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Open Camera"),
                onTap: () async {
                  Navigator.pop(context);
                  await pickImage(ImageSource.camera);
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Choose From Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  await pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image == null) return;

      // Verify if it's a crop image using ML Kit (Offline)
      // if (!kIsWeb) {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Verifying image...'),
      //         duration: Duration(seconds: 1),
      //       ),
      //     );
      //   }
      //
      //   final bool isCrop = await ImageVerificationService.isCropImage(image.path);
      //
      //   if (!isCrop) {
      //     if (mounted) {
      //       showDialog(
      //         context: context,
      //         builder: (context) => AlertDialog(
      //           title: const Text("Invalid Image"),
      //           content: const Text(
      //             "The image does not appear to be a crop or plant. "
      //                 "Please take a clear photo of your crop to proceed.",
      //           ),
      //           actions: [
      //             TextButton(
      //               onPressed: () => Navigator.pop(context),
      //               child: const Text("OK"),
      //             ),
      //           ],
      //         ),
      //       );
      //     }
      //     return;
      //   }
      // }

      final Uint8List bytes = await image.readAsBytes(); // ✅ single declaration

      final originalSize = bytes.lengthInBytes / 1024;
      if (kDebugMode) {
        print("Original Size: ${originalSize.toStringAsFixed(2)} KB");
      } // ✅ printed once

      if (kIsWeb) {
        setState(() {
          webImage = bytes;
        });
        _model.cropImage = '';
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes);

      final compressedFile = await ImageCompressHelper.compressImage(file);

      if (compressedFile != null) { // ✅ block is now properly closed
        final compressedSize = await compressedFile.length() / 1024;
        if (kDebugMode) {
          print("Compressed Size: ${compressedSize.toStringAsFixed(2)} KB");
        }

        setState(() {
          cropImage = file;
          _model.cropImage = file.path;
        });

        if (kDebugMode) {
          print("Saved Image: ${cropImage?.path}");
        }
      } // ✅ closes if (compressedFile != null)

    } catch (e) {
      if (kDebugMode) {
        print("Image Error: $e");
      }
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      final parsed = DateTime.tryParse(controller.text);
      if (parsed != null) {
        initialDate = parsed;
      }
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = SafeArea(
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: kIsWeb ? 600 : double.infinity),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Flexible(
                      child: Center(
                        child: Text(
                          'Crop Details',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Tell us what you’re growing and how it’s cultivated.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                const ProgressWidget(current: 2),
                const SizedBox(height: 20),
                if (_model.areaName?.isNotEmpty ?? false)
                  SectionCard(
                    title: 'Selected Area',
                    icon: Icons.square_foot,
                    child: Text(
                      _model.areaName!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                SectionCard(
                  title: 'Crop Name',
                  icon: Icons.energy_savings_leaf,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _cropNameController,
                        focusNode: _cropNameFocusNode,
                        hint: 'Search Or Select The Crop(Eg.Rice,etc..)',
                        suffix: const Icon(Icons.keyboard_arrow_down),
                      ),
                      _buildInlineSuggestions(
                        focusNode: _cropNameFocusNode,
                        controller: _cropNameController,
                        suggestions: _cropNameSuggestions,
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  title: 'Variety or Hybrid (Seed Type)',
                  icon: Icons.spa,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _varietyController,
                        focusNode: _varietyFocusNode,
                        hint: 'Search Or Select Variety Or Hybrid',
                        suffix: const Icon(Icons.keyboard_arrow_down),
                      ),
                      _buildInlineSuggestions(
                        focusNode: _varietyFocusNode,
                        controller: _varietyController,
                        suggestions: _varietySuggestions,
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  title: 'Planting Details',
                  icon: Icons.grass,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          buildMethodButton('Sowing'),
                          const SizedBox(width: 12),
                          buildMethodButton('Transplanting'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Planting Date',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                AppTextField(
                                  controller: _plantingDateController,
                                  hint: 'Select Date',
                                  readOnly: true,
                                  onTap: () => _selectDate(context, _plantingDateController),
                                  suffix: const Icon(Icons.calendar_month),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Expected Harvest Date',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                AppTextField(
                                  controller: _harvestDateController,
                                  hint: 'Select Date',
                                  readOnly: true,
                                  onTap: () => _selectDate(context, _harvestDateController),
                                  suffix: const Icon(Icons.calendar_month),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  title: 'Crop Duration',
                  icon: Icons.agriculture,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _durationController,
                        focusNode: _durationFocusNode,
                        hint: 'Select The growth period',
                        suffix: const Icon(Icons.keyboard_arrow_down),
                      ),
                      _buildInlineSuggestions(
                        focusNode: _durationFocusNode,
                        controller: _durationController,
                        suggestions: _durationSuggestions,
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  title: 'Plant Arrangement',
                  icon: Icons.grid_view,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _arrangementController,
                        focusNode: _arrangementFocusNode,
                        hint: 'Select The Plant Arrangement',
                        suffix: const Icon(Icons.keyboard_arrow_down),
                      ),
                      _buildInlineSuggestions(
                        focusNode: _arrangementFocusNode,
                        controller: _arrangementController,
                        suggestions: _arrangementSuggestions,
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  title: 'Crop type',
                  icon: Icons.park,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _cropTypeController,
                        focusNode: _cropTypeFocusNode,
                        hint: 'Select The Type Of Cultivation Environment',
                        suffix: const Icon(Icons.keyboard_arrow_down),
                      ),
                      _buildInlineSuggestions(
                        focusNode: _cropTypeFocusNode,
                        controller: _cropTypeController,
                        suggestions: _cropTypeSuggestions,
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  title: 'Crop Image',
                  icon: Icons.photo,
                  child: GestureDetector(
                    onTap: openCamera,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: (cropImage == null && webImage == null)
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Capture Crop Image',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Icon(Icons.camera_alt),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: kIsWeb
                                    ? (webImage != null
                                        ? Image.memory(
                                            webImage!,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : const SizedBox())
                                    : (cropImage != null
                                        ? Image.file(
                                            cropImage!,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : const SizedBox()),
                              ),
                            ),
                    ),
                  ),
                ),
                CropContinueButton(
                  onTap: () async {
                    print(
                        'userId:${widget.userId},controllerId:${widget.controllerId},edit:${widget.edit},cropId:${widget.cropId}');
                    // Update singleton instance with data from this screen
                    _model.cropName = _cropNameController.text;
                    _model.cropVariety = _varietyController.text;
                    _model.plantingMethod = _plantingMethod;
                    _model.plantingDate = _plantingDateController.text;
                    _model.expectedHarvestDate = _harvestDateController.text;
                    _model.cropDuration = _durationController.text;
                    _model.plantArrangement = _arrangementController.text;
                    _model.cropType = _cropTypeController.text;
                    _model.cropImage = kIsWeb ? '' : cropImage?.path;
                    _model.cropImageBytes = kIsWeb ? webImage : null;

                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => FieldInformationScreen(
                          cropId: widget.cropId,
                          edit: widget.edit,
                          userId: widget.userId,
                          controllerId: widget.controllerId,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: kIsWeb
          ? Row(
              children: [
                const CropAdvisoryWebSidebar(isSetup: true),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }
}
