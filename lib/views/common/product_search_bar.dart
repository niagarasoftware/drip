import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../StateManagement/search_provider.dart';
import '../../utils/formatters.dart';
import '../../view_models/base_header_view_model.dart';

class ProductSearchBar extends StatelessWidget {
  final BaseHeaderViewModel viewModel;
  final double barHeight, barRadius;
  final EdgeInsetsGeometry padding;

  const ProductSearchBar({
    super.key,
    required this.viewModel,
    required this.barHeight,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    required this.barRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        height: barHeight,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(barRadius),
          border: Border.all(color: Colors.white12, width: 0.7),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: viewModel.txtFldSearch,
                style: const TextStyle(color: Colors.white),
                inputFormatters: [
                  Formatters.upperCaseFormatter(),
                ],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: (viewModel.txtFldSearch.text.isNotEmpty ||
                      context.watch<SearchProvider>().isSearching)
                      ? IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      viewModel.clearSearch();
                      context.read<SearchProvider>().clear();
                    },
                  )
                      : null,
                  hintText: 'Search by device id / sales person',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  context.read<SearchProvider>().updateSearchDebounced(value);
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    context.read<SearchProvider>().setSearching(true);
                    context.read<SearchProvider>().updateSearchDebounced(value);
                  }
                },
              ),
            ),
            PopupMenuButton<dynamic>(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
              tooltip: 'Filter by category or model',
              itemBuilder: (BuildContext context) {
                final categoryItems = viewModel.jsonDataMap?['data']?['category'] ?? [];
                final modelItems = viewModel.jsonDataMap?['data']?['model'] ?? [];

                return [
                  const PopupMenuItem<dynamic>(
                    enabled: false,
                    child: Text("Category"),
                  ),
                  ...categoryItems.map<PopupMenuItem>((item) => PopupMenuItem(
                    value: item,
                    child: Text(item['categoryName']),
                  )),
                  const PopupMenuItem<dynamic>(
                    enabled: false,
                    child: Text("Model"),
                  ),
                  ...modelItems.map<PopupMenuItem>((item) => PopupMenuItem(
                    value: item,
                    child: Text('${item['categoryName']} - ${item['modelName']}'),
                  )),
                ];
              },
              onSelected: (selectedItem) {
                if (selectedItem is Map<String, dynamic>) {
                  viewModel.txtFldSearch.text = selectedItem.containsKey('modelName')
                      ? '${selectedItem['categoryName']} - ${selectedItem['modelName']}'
                      : '${selectedItem['categoryName']}';

                  context.read<SearchProvider>().setSearching(true);
                  context.read<SearchProvider>().setCategory(selectedItem['categoryId'] ?? 0);
                  context.read<SearchProvider>().setModel(selectedItem['modelId'] ?? 0);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}


class CustomerSearchBar extends StatelessWidget {
  final BaseHeaderViewModel viewModel;
  final double barHeight, barRadius;
  final EdgeInsetsGeometry padding;

  const CustomerSearchBar({
    super.key,
    required this.viewModel,
    required this.barHeight,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    required this.barRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        height: barHeight,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(barRadius),
          border: Border.all(color: Colors.white12, width: 0.7),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: viewModel.txtFldSearch,
                style: const TextStyle(color: Colors.white),
                inputFormatters: [
                  Formatters.upperCaseFormatter(),
                ],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: (viewModel.txtFldSearch.text.isNotEmpty ||
                      context.watch<SearchProvider>().isSearching)
                      ? IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      viewModel.clearSearch();
                      context.read<SearchProvider>().clear();
                    },
                  )
                      : null,
                  hintText: 'Search by device id / sales person',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  context.read<SearchProvider>().updateSearchDebounced(value);
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    context.read<SearchProvider>().setSearching(true);
                    context.read<SearchProvider>().updateSearchDebounced(value);
                  }
                },
              ),
            ),
            PopupMenuButton<dynamic>(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
              tooltip: 'Filter by category or model',
              itemBuilder: (BuildContext context) {
                final categoryItems = viewModel.jsonDataMap?['data']?['category'] ?? [];
                final modelItems = viewModel.jsonDataMap?['data']?['model'] ?? [];

                return [
                  const PopupMenuItem<dynamic>(
                    enabled: false,
                    child: Text("Category"),
                  ),
                  ...categoryItems.map<PopupMenuItem>((item) => PopupMenuItem(
                    value: item,
                    child: Text(item['categoryName']),
                  )),
                  const PopupMenuItem<dynamic>(
                    enabled: false,
                    child: Text("Model"),
                  ),
                  ...modelItems.map<PopupMenuItem>((item) => PopupMenuItem(
                    value: item,
                    child: Text('${item['categoryName']} - ${item['modelName']}'),
                  )),
                ];
              },
              onSelected: (selectedItem) {
                if (selectedItem is Map<String, dynamic>) {
                  viewModel.txtFldSearch.text = selectedItem.containsKey('modelName')
                      ? '${selectedItem['categoryName']} - ${selectedItem['modelName']}'
                      : '${selectedItem['categoryName']}';

                  context.read<SearchProvider>().setSearching(true);
                  context.read<SearchProvider>().setCategory(selectedItem['categoryId'] ?? 0);
                  context.read<SearchProvider>().setModel(selectedItem['modelId'] ?? 0);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}