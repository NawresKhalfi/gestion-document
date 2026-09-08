import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class T2EditTextField extends StatelessWidget {
  final bool isPassword;
  final TextEditingController mController;
  final double fontSize;
  final int maxLine;

  const T2EditTextField({
    Key? key,
    required this.isPassword,
    required this.mController,
    this.fontSize = 16.0,
    this.maxLine = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: mController,
      textFieldType: isPassword ? TextFieldType.PASSWORD : TextFieldType.NAME,
      maxLines: maxLine,
      decoration: inputDecoration(context),
      textStyle: primaryTextStyle(size: fontSize.toInt()),
    ).paddingOnly(top: 16);
  }

  InputDecoration inputDecoration(BuildContext context) {
    return InputDecoration(
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
    );
  }
}
