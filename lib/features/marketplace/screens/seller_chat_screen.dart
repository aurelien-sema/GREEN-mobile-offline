import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../models/product_model.dart';
import '../../../shared/widgets/custom_scroll_physics.dart';

class _SellerMessage {
  final String text;
  final bool isUser;
  _SellerMessage({required this.text, required this.isUser});
}

/// Messagerie avec le fournisseur d'un produit — l'app n'a pas de vendeurs
/// humains réels côté serveur (catalogue Marketplace statique), donc les
/// réponses sont simulées localement (mots-clés → réponse pré-écrite) plutôt
/// que de faire semblant de contacter un vrai interlocuteur en direct.
class SellerChatScreen extends StatefulWidget {
  final ProductModel product;
  const SellerChatScreen({required this.product, super.key});

  @override
  State<SellerChatScreen> createState() => _SellerChatScreenState();
}

class _SellerChatScreenState extends State<SellerChatScreen> {
  final List<_SellerMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final t = context.read<LocaleProvider>().t;

    setState(() {
      _messages.add(_SellerMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_SellerMessage(text: _autoReply(text, t), isUser: false));
      });
      _scrollToBottom();
    });
  }

  /// Réponse simulée par mots-clés (français/anglais/pidgin confondus, la
  /// réponse elle-même est dans la langue courante de l'app).
  String _autoReply(String message, String Function(String) t) {
    final m = message.toLowerCase();
    bool has(List<String> words) => words.any((w) => m.contains(w));

    if (has(['livrai', 'deliver', 'come', 'quand', 'when', 'time'])) {
      return t('sellerReplyDelivery');
    }
    if (has(['prix', 'price', 'coût', 'cout', 'cost', 'combien', 'how much', 'negoc'])) {
      return t('sellerReplyPrice');
    }
    if (has(['dispo', 'stock', 'available', 'reste', 'dey']) ) {
      return t('sellerReplyAvailability');
    }
    if (has(['paiement', 'payment', 'pay', 'money', 'momo'])) {
      return t('sellerReplyPayment');
    }
    return t('sellerReplyGeneric');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final t = context.watch<LocaleProvider>().t;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.product.supplierName, style: const TextStyle(fontSize: 16)),
            Text(
              widget.product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
              ),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Text(
                        t('sellerChatIntro').replaceAll('{supplier}', widget.product.supplierName),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isDarkMode ? AppColors.darkHint : AppColors.lightHint),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const SmoothScrollPhysics(),
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              t('sellerTyping'),
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                              ),
                            ),
                          ),
                        );
                      }
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? (isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary)
                                : (isDarkMode ? AppColors.darkSurface : AppColors.lightSurface),
                            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(color: msg.isUser ? Colors.white : null),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: t('sellerMessageHint'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLarge)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
