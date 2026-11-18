import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../widgets/password_input_field.dart';
import '../widgets/phone_input_field.dart';
import '../widgets/continue_button.dart';

import '../../../../utils/constants.dart';
import '../../../../view_models/login_view_model.dart';

class WideLayout extends StatelessWidget {
  final bool isOro, isATel;
  final LoginViewModel viewModel;

  const WideLayout({
    super.key,
    required this.isOro,
    required this.viewModel,
    required this.isATel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _companyLogo(context),
        _buildLoginInputs(context),
      ],
    );
  }

  Widget _companyLogo(BuildContext context) {
    return Expanded(
      child: Container(
        height: double.infinity,
        color: Theme.of(context).primaryColorDark,
        child: isOro ? Padding(
          padding: const EdgeInsets.all(50.0),
          child: SvgPicture.asset('assets/svg_images/login_left_picture.svg'),
        ) : isATel ? Padding(
          padding: const EdgeInsets.all(50.0),
          child: SvgPicture.asset('assets/svg_images/agritel_left_picture.svg'),
        ) : const Image(
          image: AssetImage('assets/png/lk_login_left_picture.png'),
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  Widget _buildLoginInputs(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            isATel ? const SizedBox() :
            isOro ? const Expanded(
              child: Row(
                children: [
                  Spacer(flex: 3),
                  Image(image: AssetImage('assets/png/login_top_corner.png')),
                ],
              ),
            ) :
            Padding(
              padding: const EdgeInsets.only(left: 150, top: 40),
              child: SvgPicture.asset(
                'assets/svg_images/lk_login_top_corner.svg',
                fit: BoxFit.fitWidth,
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    if (isOro)...[
                      SvgPicture.asset('assets/svg_images/oro_logo.svg', fit: BoxFit.cover),
                      const SizedBox(height: 10)
                    ],
                    if (isATel)...[
                      const SizedBox(height: 50),
                      const Image(
                        image: AssetImage('assets/png/agritel_logo.png'),
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 20)
                    ],
                    Padding(
                      padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
                      child: Text(
                        AppConstants.appShortContent,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const PhoneInputField(isWeb: true),
                    const SizedBox(height: 15),
                    const PasswordInputField(isWeb: true),
                    if (viewModel.errorMessage.isNotEmpty)
                      SizedBox(
                        width: 400,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 40, top: 4),
                          child: Text(
                            viewModel.errorMessage,
                            textAlign: TextAlign.left,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.only(left: 40),
                      child: ContinueButton(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}