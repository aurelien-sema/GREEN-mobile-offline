import 'package:flutter/material.dart';
import 'package:green_app/core/constants/dimensions.dart';

/// Champ de texte personnalisé réutilisable
class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool showPasswordToggle;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.showPasswordToggle
              ? _isObscured
              : widget.obscureText,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hint ?? widget.label,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: AppDimensions.iconSmall)
                : null,
            suffixIcon: widget.showPasswordToggle
                ? IconButton(
                    icon: Icon(
                      _isObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: AppDimensions.iconSmall,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
