import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../flavors.dart';
import '../../../../view_models/product_category_view_model.dart';

class ProductView extends StatelessWidget {
  const ProductView({super.key, required this.isWideScreen});
  final bool isWideScreen;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProductCategoryViewModel>();
    final isLoading = viewModel.isLoadingCategory;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: isWideScreen ? Skeletonizer(
        enabled: isLoading,
        child: GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: screenWidth > 1300 ? 5 :
            screenWidth > 1100 ? 4 : 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 4 / 2.7,
          ),
          itemCount: isLoading ? 10 : viewModel.categoryList.length,
          itemBuilder: (context, index) {
            final item = isLoading ? null : viewModel.categoryList[index];

            return Card(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/Images/Png/${F.appFlavor!.name.contains('oro') ? 'Oro' :
                    F.appFlavor!.name.contains('agritel') ? 'Agritel' :
                    'SmartComm'}/category_${index + 1}.png",
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item?.categoryName ?? "Loading...",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Device description',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ) :
      Skeletonizer(
        enabled: isLoading,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: isLoading ? 10 : viewModel.categoryList.length,
          itemBuilder: (context, index) {
            final item = isLoading ? null : viewModel.categoryList[index];
            return ListTile(
              tileColor: Colors.white,
              leading: Image.asset(
                "assets/Images/Png/${F.appFlavor!.name.contains('oro') ? 'Oro' :
                F.appFlavor!.name.contains('agritel') ? 'Agritel' :
                'SmartComm'}/category_${index + 1}.png",
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  print('image loding error:$error');
                  return const Icon(Icons.error);
                },
              ),
              title: Text(
                item?.categoryName ?? "Loading...",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Device description',
                style: TextStyle(color: Colors.black54),
              ),
              trailing: const Icon(Icons.arrow_right_outlined),
            );
          },
        ),
      ),
    );
  }
}