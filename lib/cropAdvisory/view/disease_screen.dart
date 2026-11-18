import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class DiseaseScreen extends StatefulWidget {
  const DiseaseScreen({super.key});

  @override
  State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen> with SingleTickerProviderStateMixin {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Opens camera, captures photo, and then starts scanning animation
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _image = photo;
        });
        _runScanningEffect();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error capturing image: $e");
      }
    }
  }

  // Runs ONLY the scanning animation and simulates analysis results
  Future<void> _runScanningEffect() async {
    setState(() {
      _isScanning = true;
    });
    _animationController.repeat(reverse: true);
    
    // Simulate scanning/analysis for 4 seconds
    await Future.delayed(const Duration(seconds: 4));
    
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
      _animationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: kIsWeb ? 800 : double.infinity,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Top Image Section ---
                Stack(
                  children: [
                    Container(
                      height: kIsWeb ? 400 : 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        image: DecorationImage(
                          image: _image == null
                              ? const NetworkImage(
                                  'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?q=80&w=2070&auto=format&fit=crop',
                                )
                              : (kIsWeb 
                                  ? NetworkImage(_image!.path) 
                                  : FileImage(File(_image!.path))) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    // Scanning Animation Overlay
                    if (_isScanning)
                      AnimatedBuilder(
                        animation:  _animationController,
                        builder: (context, child) {
                          return Positioned(
                            top: _animationController.value * (kIsWeb ? 400 : 300),
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.lightGreen,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF1B7F8A).withOpacity(0.8),
                                    blurRadius: 15,
                                    spreadRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    
                    if (_isScanning)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.2),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: Colors.white),
                                const SizedBox(height: 10),
                                Text(
                                  "Scanning for Health Issues...",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Satellite Overlay / Mask (only show when no image or not scanning)
                    if (_image == null && !_isScanning)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                    
                    if (_image == null && !_isScanning)
                      Center(
                        child: Container(
                          width: 200,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.withOpacity(0.5),
                                Colors.green.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    // Overlay text
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _image == null 
                            ? 'Generated by Satellite imagery services'
                            : 'Field Analysis: Captured Image',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    
                    // Fullscreen Icon (Trigger SCAN ONLY, no camera)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                           _image == null ? _takePhoto  : _runScanningEffect();
                           // _runScanningEffect();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // --- Content Section ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _image == null ? 'Crop Management' : 'Analysis Results',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 1. Fertigation Card
                      _InfoCard(
                        icon: Icons.science_outlined,
                        title: 'Fertigation',
                        description: Text(
                          (_isScanning || _image == null) ? 'Analyzing fertilizer levels...' : 'A total of 50 kg of fertilizer was successfully applied. Nitrogen levels are currently optimal for crop growth.',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Water Management Card
                      _InfoCard(
                        icon: Icons.water_drop_outlined,
                        title: 'Water Management',
                        description: Text(
                          (_isScanning || _image == null) ? 'Calculating soil moisture...' : 'Irrigation cycle efficient. Soil moisture is at 68%. Next watering scheduled for 6:00 PM.',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. Disease Details Card
                      _InfoCard(
                        icon: Icons.bug_report_outlined,
                        title: 'Disease Details',
                        description: Text(
                          (_isScanning || _image == null) ? 'Detecting pathogens...' : (_image == null ? 'No data from satellite yet.' : 'Possible Early Blight detected in lower leaves. Risk level: Low. Action: Monitor closely.'),
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 4. Prestige / Pest Management Card
                      _InfoCard(
                        icon: Icons.health_and_safety_outlined,
                        title: 'Pest Management (Prestige)',
                        description: Text(
                          (_isScanning || _image == null) ? 'Analyzing pest activity...' : 'Prestige status: Safe. Natural predators observed. No chemical pesticides required currently.',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54, height: 1.5),
                        ),
                      ),
                      
                      const SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // FAB Opens CAMERA
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: InkWell(
          onTap: _isScanning ? null : _takePhoto,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _isScanning ? Colors.grey : const Color(0xFF1B7F8A),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(0),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(15.0),
              child: Icon(
                Icons.photo_camera,
                size: 30,
                color: Colors.white,
               ),

            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          description,
        ],
      ),
    );
  }
}
