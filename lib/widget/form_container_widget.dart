import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FormContainerWidget extends StatefulWidget {
  final TextEditingController? controller;
  final Key? fieldKey;
  final bool? isPasswordField;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputType? inputType;
  final String? iconPath;
  final String? title;

  const FormContainerWidget({
    super.key,
    this.controller,
    this.isPasswordField,
    this.fieldKey,
    this.hintText,
    this.labelText,
    this.helperText,
    this.onSaved,
    this.validator,
    this.onFieldSubmitted,
    this.inputType,
    this.iconPath,
    this.title,
  });

  @override
  _FormContainerWidgetState createState() => _FormContainerWidgetState();
}

class _FormContainerWidgetState extends State<FormContainerWidget> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.title ?? '',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color.fromARGB(255, 0, 0, 0),
              width: 1.0,
            ),
          ),
          child:Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextFormField(
              style: const TextStyle(color: Colors.black),
              controller: widget.controller,
              keyboardType: widget.inputType,
              key: widget.fieldKey,
              obscureText: widget.isPasswordField == true ? _obscureText : false,
              onSaved: widget.onSaved,
              validator: widget.validator,
              onFieldSubmitted: widget.onFieldSubmitted,
              decoration: InputDecoration(
                fillColor: Colors.white,
                icon: SizedBox(
                  width: 35,
                  height: 35,
                  child: Padding(
                    padding: const EdgeInsets.only(top:8.0, bottom: 8.0,left: 8.0),
                    child: SvgPicture.asset(
                    widget.iconPath!,
                    width: 20,
                    height: 20,
                    ),
                  ),
                ),
                border: InputBorder.none,
              filled: true,
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Colors.black45),
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0), // Adjust padding for vertical centering
              suffixIcon: widget.isPasswordField == true ? GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                child: widget.isPasswordField == true
                    ? Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: _obscureText == false ? Colors.black : Colors.grey,
                      )
                    : const Text(""),
              ):null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}