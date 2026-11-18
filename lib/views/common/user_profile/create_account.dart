import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:oro_drip_irrigation/utils/Theme/oro_theme.dart';
import 'package:provider/provider.dart';

import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/enums.dart';
import '../../../utils/formatters.dart';
import '../../../view_models/create_account_view_model.dart';


class CreateAccount extends StatelessWidget {
  const CreateAccount({super.key, required this.userId, required this.role,
    required this.customerId, required this.onAccountCreated});

  final int userId, customerId;
  final UserRole role;
  final Function(Map<String, dynamic>) onAccountCreated;

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = CreateAccountViewModel(Repository(HttpService()), onAccountCreatedSuccess: (result) async {
          await onAccountCreated(result);
          Navigator.pop(context);
        });
        viewModel.getCountryList();
        return viewModel;
      },
      child: Consumer<CreateAccountViewModel>(
        builder: (context, viewModel, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2,right: 2, top: 2),
                child: ListTile(
                  title: Text(
                    AppConstants.getFormTitle(role),
                    style: const TextStyle(fontSize: 20),
                  ),
                  subtitle: const Text(
                    AppConstants.pleaseFillDetails,
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: role.name == "dealer"  ?
                  DropdownButton<AccountType>(
                    value: viewModel.accountType,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: AccountType.customer,
                        child: Text('Customer'),
                      ),
                      DropdownMenuItem(
                        value: AccountType.dealer,
                        child: Text('Dealer'),
                      ),
                    ],
                    onChanged: (value) {
                      viewModel.setAccountType(value!);
                    },
                  ) : null,
                ),
              ),
              const Divider(height: 0),
              viewModel.errorMsg!='' ? Container(
                  width: MediaQuery.sizeOf(context).width,
                  color: Colors.redAccent,
                  child: Text(viewModel.errorMsg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal), textAlign: TextAlign.center,)
              ) :
              const SizedBox(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: viewModel.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Full Name
                          TextFormField(
                            keyboardType: TextInputType.name,
                            decoration: InputDecoration(
                              labelText: AppConstants.fullName,
                              icon: Icon(Icons.text_fields, color: Theme.of(context).primaryColorDark),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppConstants.getNameError(role);
                              }
                              final regex = RegExp(r'^[a-zA-Z ]+$');
                              if (!regex.hasMatch(value)) {
                                return AppConstants.nameValidationError;
                              }
                              return null;
                            },
                            onSaved: (value) => viewModel.name = value,
                            inputFormatters: [
                              Formatters.capitalizeFirstLetter(),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: IntlPhoneField(
                              controller: viewModel.mobileNoController,
                              focusNode: FocusNode(),
                              decoration: InputDecoration(
                                labelText: AppConstants.mobileNumber,
                                icon: Icon(Icons.phone_outlined, color: Theme.of(context).primaryColorDark),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey, width: 0.5),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue, width: 1.0),
                                ),
                                errorStyle: const TextStyle(fontSize: 12, color: Colors.redAccent),
                              ),
                              initialCountryCode: 'IN', // default India, but user can change
                              showDropdownIcon: true, // show country dropdown
                              dropdownIconPosition: IconPosition.trailing,
                              dropdownIcon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                              languageCode: "en",
                              keyboardType: TextInputType.phone,

                              validator: (phone) {
                                final value = phone?.number ?? '';
                                if (value.isEmpty) {
                                  return AppConstants.getMobileError(role);
                                }
                                if (value.length < 6) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },

                              onChanged: (phone) {
                                print(phone.completeNumber);
                              },
                              onCountryChanged: (country) {
                                viewModel.dialCode = country.dialCode;
                              },
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Email
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: AppConstants.emailAddress,
                              icon: Icon(Icons.email_outlined, color: Theme.of(context).primaryColorDark),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppConstants.getEmailError(role);
                              }
                              if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                                return AppConstants.enterValidEmail;
                              }
                              return null;
                            },
                            onSaved: (email) => viewModel.email = email,
                          ),

                          const SizedBox(height: 15),

                          // Country Dropdown
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: AppConstants.country,
                              icon: Icon(CupertinoIcons.globe, color: Theme.of(context).primaryColorDark),
                            ),
                            value: viewModel.country,
                            items: viewModel.countries.map((countryItem) {
                              return DropdownMenuItem(
                                value: countryItem,
                                child: Text(countryItem),
                              );
                            }).toList(),
                            onChanged: (value) {
                              viewModel.country = value;
                              viewModel.state = null;
                              viewModel.states.clear();
                              viewModel.selectedCountryID = viewModel.getCountryIdByName(value.toString())!;
                              viewModel.getStateList(viewModel.selectedCountryID.toString());
                            },
                            validator: (value) {
                              if (value == null) {
                                return AppConstants.getCountryError(role);
                              }
                              return null;
                            },
                            onSaved: (value) => viewModel.country = value,
                          ),

                          const SizedBox(height: 20),

                          // State Dropdown
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: AppConstants.state,
                              icon: Icon(CupertinoIcons.placemark, color: Theme.of(context).primaryColorDark),
                            ),
                            value: viewModel.state,
                            items: viewModel.states.map((stateItem) {
                              return DropdownMenuItem(
                                value: stateItem,
                                child: Text(stateItem),
                              );
                            }).toList(),
                            onChanged: (value) {
                              viewModel.state = value;
                              viewModel.selectedStateID = viewModel.getStateIdByName(value.toString())!;
                            },
                            validator: (value) {
                              if (value == null) {
                                return AppConstants.getStateError(role);
                              }
                              return null;
                            },
                            onSaved: (value) => viewModel.state = value,
                          ),

                          const SizedBox(height: 20),

                          // City
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: AppConstants.city,
                              icon: Icon(Icons.location_city, color: Theme.of(context).primaryColorDark),
                            ),
                            keyboardType: TextInputType.name,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppConstants.getCityError(role);
                              }
                              return null;
                            },
                            onSaved: (value) => viewModel.city = value,
                            inputFormatters: [
                              Formatters.capitalizeFirstLetter(),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // Address
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: AppConstants.address,
                              icon: Icon(Icons.linear_scale, color: Theme.of(context).primaryColorDark),
                            ),
                            keyboardType: TextInputType.streetAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppConstants.getAddressError(role);
                              }
                              return null;
                            },
                            onSaved: (value) => viewModel.address = value,
                          ),

                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 56,
                child: Column(
                  children: [
                    ListTile(
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MaterialButton(
                            onPressed:() {
                              Navigator.pop(context);
                            },
                            textColor: Colors.white,
                            color: Colors.redAccent,
                            child: const Text('Cancel',style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          MaterialButton(
                            onPressed: () => viewModel.createAccount(userId, role, customerId),
                            textColor: Colors.white,
                            color: Theme.of(context).primaryColor,
                            child: const Text('Create Account',style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}