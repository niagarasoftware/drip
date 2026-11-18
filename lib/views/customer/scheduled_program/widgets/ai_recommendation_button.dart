import 'package:flutter/material.dart';
import 'package:popover/popover.dart';

import '../../../../services/ai_advisory_service.dart';

class AiRecommendationButton extends StatelessWidget {
  final AiAdvisoryService aiService;
  final int userId, controllerId;

  const AiRecommendationButton({super.key, required this.aiService, required this.userId, required this.controllerId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        aiService.getAdvisory(userId: userId, controllerId: controllerId);
        showPopover(
          context: context,
          bodyBuilder: (context) => ValueListenableBuilder<Map<String, dynamic>?>(
            valueListenable: aiService.aiResponseNotifier,
            builder: (context, response, child) {
              if (response == null) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)
                  ),
                );
              }
              if (response.containsKey('error')) return Text(response['error']);

              return Padding(
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("✅ Suggested Irrigation Percentage: ${response['percentage']}%",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('${response['reason']}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () =>Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                print("✔️ Applied ${response['percentage']}%");
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                              child: const Text('Apply', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          direction: PopoverDirection.bottom,
          arrowHeight: 15,
          arrowWidth: 30,
        );
      },
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(13),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      child: const Text('AI-R', style: TextStyle(color: Colors.white, fontSize: 10)),
    );
  }
}