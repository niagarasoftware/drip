import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../IrrigationProgram/view/schedule_screen.dart';
import '../model/preference_data_model.dart';
import '../state_management/preference_provider.dart';

class MoistureSettings extends StatelessWidget {
  const MoistureSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            height: 30,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColorLight,
                borderRadius: const BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(3))
            ),
            child: const Center(
              child: Text(
                "Moisture Settings",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white,),
              ),
            ),
          ),
        ),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                color: Colors.white,
                border: Border.all(color: Theme.of(context).primaryColorLight, width: 0.3)
              // boxShadow: AppProperties.customBoxShadowLiteTheme
            ),
            child: Consumer<PreferenceProvider>(
              builder: (context, provider, _) => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                itemCount: provider.moistureSettings?.setting.length ?? 0,
                itemBuilder: (context, index) => _buildSettingItem(
                  context,
                  provider,
                  provider.moistureSettings!.setting[index],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
      BuildContext context,
      PreferenceProvider provider,
      WidgetSetting item,
      ) {
    const settingOptions = ["Both", "Any", "Moisture 1", "Moisture 2"];

    switch (item.serialNumber) {
      case 1:
        return _SwitchTile(
          title: item.title,
          value: item.value as bool,
          onChanged: (value) => provider.updateMoistureSwitchValue(item.title, value),
        );
      case 2:
        return _RadioTile(
          title: item.title,
          options: settingOptions,
          value: item.value as int,
          onChanged: (value) => provider.updateRadioValue(item.title, value!),
        );
      default:
        final values = (item.value as String).split(',');
        return Column(
          children: [
            if(item.serialNumber == 3)
              Row(
                children: [
                  Expanded(child: Container()),
                  const SizedBox(
                    width: 80,
                    child: Text("Min"),
                  ),
                  const SizedBox(
                    width: 80,
                    child: Text("Max"),
                  ),
                ],
              ),
            _RangeInputTile(
              title: item.title,
              firstValue: values[0],
              secondValue: values[1],
              onChanged1: (value) => provider.updateMoistureSettingValue(item.title, value, true),
              onChanged2: (value) => provider.updateMoistureSettingValue(item.title, value, false),
            ),
          ],
        );
    }
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: IntrinsicWidth(
        child: Switch(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String title;
  final List<String> options;
  final int value;
  final ValueChanged<int?> onChanged;

  const _RadioTile({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<int>(
                  value: (entry.key+1),
                  groupValue: value,
                  onChanged: onChanged,
                ),
                Text(entry.value),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class _RangeInputTile extends StatelessWidget {
  final String title;
  final String firstValue;
  final String secondValue;
  final ValueChanged<String> onChanged1;
  final ValueChanged<String> onChanged2;

  const _RangeInputTile({
    required this.title,
    required this.firstValue,
    required this.secondValue,
    required this.onChanged1,
    required this.onChanged2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title)),
          _NumberInputField(
            value: firstValue,
            onChanged: onChanged1,
          ),
          const SizedBox(width: 16),
          _NumberInputField(
            value: secondValue,
            onChanged: onChanged2,
          ),
        ],
      ),
    );
  }
}

class _NumberInputField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _NumberInputField({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: TextFormField(
        initialValue: value,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: "000",
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide.none,
          ),
          fillColor: cardColor,
          filled: true,
        ),
      ),
    );
  }
}