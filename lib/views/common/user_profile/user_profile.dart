import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_provider.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../utils/snack_bar.dart';
import '../../../view_models/account_setting_view_model.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key, required this.isNarrow});
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final loggedInUser = context.read<UserProvider>().loggedInUser;
    final viewedCustomer = context.read<UserProvider>().viewedCustomer!;

    return ChangeNotifierProvider(
      create: (_) => UserSettingViewModel(
        Repository(HttpService()),
        viewedCustomer.name,
        viewedCustomer.countryCode,
        viewedCustomer.mobileNo,
        viewedCustomer.email,
        viewedCustomer.role.name,
      ),
      child: Consumer<UserSettingViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: isNarrow ? AppBar(title: const Text('Profile')) : null,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  tileColor: Colors.white,
                  title: Text(
                    "Profile Settings",
                    style: TextStyle(fontSize: 18, color: Colors.black45),
                  ),
                  subtitle: Text(
                    'Real-time Information and activity of your property.',
                    style: TextStyle(color: Colors.black26),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 220,
                          child: Form(
                            key: viewModel.formKey,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: TextFormField(
                                      controller: viewModel.controllerUsrName,
                                      decoration: const InputDecoration(
                                        labelText: 'Full Name',
                                        prefixIcon: Icon(Icons.account_circle, color: Colors.black38),
                                        filled: true,
                                        fillColor: Colors.white,
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey, width: 0.5),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: IntlPhoneField(
                                      focusNode: FocusNode(),
                                      decoration: InputDecoration(
                                        labelText: null,
                                        prefixIcon: const Icon(Icons.phone, color: Colors.black38),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.clear, color: Colors.red),
                                          onPressed: () => viewModel.controllerMblNo.clear(),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                                        counterText: '',
                                        enabledBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey, width: 0.5),
                                        ),
                                      ),
                                      languageCode: "en",
                                      initialCountryCode: 'IN',
                                      controller: viewModel.controllerMblNo,
                                      onChanged: (phone) {
                                        print(phone.completeNumber);
                                      },
                                      onCountryChanged: (country) =>
                                      viewModel.countryCode = country.dialCode,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: TextFormField(
                                      controller: viewModel.controllerEmail,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Email Address',
                                        prefixIcon: Icon(Icons.email, color: Colors.black38),
                                        filled: true,
                                        fillColor: Colors.white,
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey, width: 0.5),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email address';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const ListTile(
                          tileColor: Colors.transparent,
                          title: Text(
                            "Security",
                            style: TextStyle(fontSize: 18, color: Colors.black45),
                          ),
                          subtitle: Text(
                            'Modify your current password',
                            style: TextStyle(color: Colors.black26),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: TextFormField(
                            controller: viewModel.controllerNewPwd,
                            obscureText: viewModel.isObscureNpw,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: const Icon(Icons.password, color: Colors.black38),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  viewModel.isObscureNpw ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.black87,
                                ),
                                onPressed: () => viewModel.onIsObscureChangedToNpw(),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey, width: 0.5),
                              ),
                            ),
                            autofillHints: const [AutofillHints.newPassword],
                            keyboardType: TextInputType.visiblePassword,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 10, right: 16),
                          child: TextFormField(
                            controller: viewModel.controllerConfirmPwd,
                            obscureText: viewModel.isObscureCpw,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.password, color: Colors.black38),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  viewModel.isObscureCpw ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.black87,
                                ),
                                onPressed: () => viewModel.onIsObscureChangedToCpw(),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey, width: 0.5),
                              ),
                            ),
                            autofillHints: const [AutofillHints.newPassword],
                            keyboardType: TextInputType.visiblePassword,
                            validator: (value) {
                              if (viewModel.controllerNewPwd.text.isNotEmpty ||
                                  (value != null && value.isNotEmpty)) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                } else if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                } else if (value != viewModel.controllerNewPwd.text) {
                                  return 'Passwords do not match';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        viewModel.errorMsg.isNotEmpty ? Text(viewModel.errorMsg, style: const TextStyle(color: Colors.red)) :
                        const SizedBox(),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  height: 45,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Spacer(),
                      MaterialButton(
                        minWidth:100,
                        height: 40,
                        color: Colors.red,
                        textColor: Colors.white,
                        child: const Text('CANCEL'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      MaterialButton(
                        minWidth:175,
                        height: 40,
                        color: Theme.of(context).primaryColorDark,
                        textColor: Colors.white,
                        child: const Text('SAVE CHANGES'),
                        onPressed: () async {
                          final response = await viewModel.updateUserProfile(
                            context,
                            viewedCustomer.id,
                            loggedInUser.id,
                          );

                          if (response != null) {
                            Navigator.pop(context);
                            GlobalSnackBar.show(context, response["message"], response["code"]);
                          } else {
                            GlobalSnackBar.show(context, 'profile update cancelled', 400);
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}