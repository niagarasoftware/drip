import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/cropAdvisory/view/crop_advisory_main_screen.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';
import '../../utils/snack_bar.dart';
import '../model/cropadvisory_model.dart';
import 'getUserInformationScreen.dart';

class CropListScreen extends StatefulWidget {
  const CropListScreen({
    Key? key,
    required this.userId,
    required this.controllerId,
    this.isInsideTabs = false,
  }) : super(key: key);

  final int userId, controllerId;
  final bool isInsideTabs;

  @override
  State<CropListScreen> createState() => _CropListScreenState();
}

class _CropListScreenState extends State<CropListScreen> {
  bool _isLoading = true;
  List<CropAdvisoryModel> cropList = [];
  int cropId = 1;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final repository = Repository(HttpService());

      final response = await repository.getCropList({
        "userId": widget.userId,
        "controllerId": widget.controllerId,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> cropData = body['data'];

        setState(() {
          cropList =
              cropData.map((e) => CropAdvisoryModel.fromJson(e)).toList();
          cropId = cropData.length + 1;
        });
      }
    } catch (e) {
      AppLog.log(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> deleteCropList(int cropId) async {
    try {
      final repository = Repository(HttpService());

      final response = await repository.deleteCropList({
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "cropId": cropId
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (mounted) {
          GlobalSnackBar.show(context, body['message'], response.statusCode);
        }
        setState(() {
          fetchData();
        });
      }
    } catch (e) {
      AppLog.log(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Use PopScope to handle back button behavior
    return PopScope(
      canPop: !widget.isInsideTabs, // Prevent default pop if inside tabs
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.isInsideTabs) {
          // Exits MainScreen flow and goes back to AIChatScreen/Root
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text("Crop List"),
            // ✅ FIX: Custom back button for when list is pushed inside tabs
            leading: widget.isInsideTabs 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                )
              : null,
          ),
          body:  _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: kIsWeb ? 800 : double.infinity),
          child: ListView.builder(
            itemCount: cropList.length,
            itemBuilder: (context, index) {
              final crop = cropList[index];
  
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: () {
                        if (widget.isInsideTabs) {
                          // ✅ FIX: Switch crop and reset the main screen flow 
                          // but keep the underlying AIChatScreen (isFirst route)
                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => CropAdvisoryMainScreen(
                                      userId: widget.userId,
                                      controllerId: widget.controllerId,
                                      cropModel: crop,
                                    )),
                            (route) => route.isFirst,
                          );
                        } else {
                          // Normal entry from AIChat -> CropList -> Select
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CropAdvisoryMainScreen(
                                      userId: widget.userId,
                                      controllerId: widget.controllerId,
                                      cropModel: crop,
                                    )),
                          );
                        }
                      },
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xff0E8797).withOpacity(0.1),
                        child: const Icon(Icons.eco, color: Color(0xff0E8797)),
                      ),
                      title: Text(
                        crop.cropName ?? 'Unnamed Crop',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "${crop.cropType ?? 'N/A'} • ${crop.farmName ?? 'No farm name'}",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Color(0xff0E8797)),
                            onPressed: () async {
                              CropAdvisoryModel.instance.fromJson(crop.toJson());
                              CropAdvisoryModel.instance.cropId = crop.cropId;
                              CropAdvisoryModel.instance.userId = widget.userId;
                              CropAdvisoryModel.instance.controllerId = widget.controllerId;
  
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Cropinformationscreen(
                                    userId: widget.userId,
                                    controllerId: widget.controllerId,
                                    cropId: crop.cropId!,
                                    edit: true,
                                  ),
                                ),
                              );
                              fetchData();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              bool? confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Delete Crop"),
                                  content: const Text("Are you sure you want to delete this crop?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                deleteCropList(crop.cropId!);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),),),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            CropAdvisoryModel.instance.reset();
            CropAdvisoryModel.instance.userId = widget.userId;
            CropAdvisoryModel.instance.controllerId = widget.controllerId;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Cropinformationscreen(
                  userId: widget.userId,
                  controllerId: widget.controllerId,
                  cropId: cropId,
                  edit: false,
                ),
              ),
            );
            fetchData();
          },
          icon: const Icon(Icons.add),
          label: const Text("Create Crop"),
          backgroundColor: const Color(0xff0E8797),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
