import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final bool isOutlined;
  final bool disabled;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.isOutlined = false,
    this.disabled = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (!widget.disabled && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _onTapUp(_) {
    // Ne déclenche que l'animation ici : InkWell.onTap est l'unique
    // déclencheur de widget.onPressed, pour éviter un double appel sur un
    // même tap (GestureDetector + InkWell empilés déclenchaient tous deux
    // l'action auparavant).
    if (!widget.disabled && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final outlinedColor = isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: !widget.isOutlined ? AppColors.buttonGradient : null,
            border: widget.isOutlined
                ? Border.all(color: outlinedColor, width: 1.5)
                : null,
            // Forme pilule (rayon = moitié de la hauteur), conforme à la
            // direction "Clean Emerald" des maquettes.
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: !widget.disabled && !widget.isOutlined
                ? [
                    BoxShadow(
                      color: const Color.fromRGBO(46, 139, 87, 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
            color: widget.isOutlined ? Colors.transparent : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.disabled || widget.isLoading
                  ? null
                  : widget.onPressed,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.isOutlined ? outlinedColor : Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: widget.isOutlined ? outlinedColor : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
