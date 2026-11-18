import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/admin_dealer/customer_model.dart';
import '../../view_models/admin_dealer/customer_search_view_model.dart';

class AllCustomerSearchBar extends StatefulWidget {
  final CustomerSearchViewModel viewModel;
  final double barHeight;
  final double barRadius;
  final Function(Customer)? onCustomerSelected;
  final String hintText;

  const AllCustomerSearchBar({
    super.key,
    required this.viewModel,
    this.barHeight = 40,
    this.barRadius = 20,
    this.onCustomerSelected,
    this.hintText = 'Search by customer name or mobile number...',
  });

  @override
  State<AllCustomerSearchBar> createState() => _AllCustomerSearchBarState();
}

class _AllCustomerSearchBarState extends State<AllCustomerSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  OverlayEntry? _overlayEntry;
  final GlobalKey _searchBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChange);

    // Add listener to ViewModel to update overlay when results change
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChange);
    widget.viewModel.removeListener(_onViewModelChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onViewModelChanged() {
    // Update overlay when ViewModel changes (results loaded or loading state changes)
    if (_overlayEntry != null && mounted) {
      _refreshOverlay();
    }
  }

  void _refreshOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _searchController.text.isNotEmpty) {
      _showOverlay();
    } else if (!_focusNode.hasFocus) {
      // Delay removal to allow tap to register
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();

      final bool isMobileNumber = RegExp(r'^[0-9+\-\s()]+$').hasMatch(query) &&
          query.replaceAll(RegExp(r'[^0-9]'), '').length >= 6;

      // Clear previous results and show loading
      widget.viewModel.searchCustomers(query);

      // Show overlay immediately with loading state
      if (query.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();

    if (!mounted) return;

    try {
      final RenderBox? renderBox = _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: position.dy + size.height + 5,
          left: position.dx,
          width: size.width,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildResultsList(),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
    } catch (e) {
      print('Error showing overlay: $e');
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectCustomer(Customer customer) {
    // First remove the overlay
    _removeOverlay();

    // Clear the search
    _searchController.clear();
    widget.viewModel.clearSearch();
    _focusNode.unfocus();

    // Call the callback
    if (widget.onCustomerSelected != null) {
      widget.onCustomerSelected!(customer);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    widget.viewModel.clearSearch();
    _focusNode.unfocus();
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _searchBarKey,
      child: Column(
        children: [
          Container(
            height: widget.barHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(widget.barRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.search, color: Colors.grey, size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      border: InputBorder.none,
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: _clearSearch,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    // This will be called whenever the overlay rebuilds
    if (widget.viewModel.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: 8),
              Text(
                'Searching...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.viewModel.errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(
                widget.viewModel.errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (widget.viewModel.searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No customers found',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.viewModel.searchResults.length,
      itemBuilder: (context, index) {
        final customer = widget.viewModel.searchResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              customer.userName.isNotEmpty ? customer.userName[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            customer.userName,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              const Icon(Icons.phone, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '+${customer.countryCode} ${customer.mobileNumber}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            _selectCustomer(customer);
          },
        );
      },
    );
  }
}