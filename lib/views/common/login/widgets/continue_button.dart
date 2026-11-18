import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';

import '../../../../view_models/login_view_model.dart';

class ContinueButton extends StatelessWidget {
  const ContinueButton({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LoginViewModel>(context);
    return SizedBox(
      width: 200,
      height: 45.0,
      child: MaterialButton(
        color: Theme.of(context).primaryColorLight,
        textColor: Colors.white,
        onPressed: viewModel.login,
        child: viewModel.isLoading 
            ? const LoadingIndicator(indicatorType: Indicator.ballPulse, colors: [Colors.white])
            : const Text('CONTINUE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}