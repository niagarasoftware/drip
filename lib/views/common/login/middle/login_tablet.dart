import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../flavors.dart';
import '../../../../view_models/login_view_model.dart';
import '../widgets/wide_layout.dart';

class LoginTablet extends StatelessWidget {
  const LoginTablet({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LoginViewModel>(context);
    final isOro = F.appFlavor!.name.contains('oro');
    final isATel = F.appFlavor!.name.contains('agritel');
    return Scaffold(
      body: SafeArea(
        child: WideLayout(isOro: isOro, viewModel: viewModel, isATel: isATel),
      ),
    );
  }

}