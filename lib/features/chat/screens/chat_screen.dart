import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/gemini/gemini_service.dart';
import '../../../services/chat_history_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../shared/models/message.dart';
import '../../../shared/widgets/animated_chat_message.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/animation_effects.dart';
import '../../../shared/widgets/custom_scroll_physics.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  final String? cacheKey;
  final bool autoSend;
  const ChatScreen({super.key, this.initialMessage, this.cacheKey, this.autoSend = true});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  final List<Message> _messages = [];
  bool _isLoading = false;
  List<ChatSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _loadSessions();
    
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageController.text = widget.initialMessage!;
        if (widget.autoSend) {
          _sendMessage(cacheKey: widget.cacheKey);
        }
      });
    } else {
      _fetchInitialGreeting();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final sessions = await chatHistoryService.getAllSessions();
    if (mounted) {
      setState(() => _sessions = sessions);
    }
  }

  Future<void> _startNewChat() async {
    // ignore: unused_local_variable
    final session = await chatHistoryService.createNewSession();
    if (mounted) {
      setState(() {
        _messages.clear();
        _loadSessions();
      });
      _fetchInitialGreeting();
    }
  }

  Future<void> _loadSession(String sessionId) async {
    await chatHistoryService.switchToSession(sessionId);
    final session = await chatHistoryService.getSessionById(sessionId);
    if (session != null && mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(
          session.messages.map(
            (msg) => Message(
              id: msg.id,
              content: msg.content,
              isUser: msg.role == 'user',
              timestamp: msg.timestamp,
            ),
          ),
        );
      });
      _scrollToBottom();
    }
    Navigator.pop(context); // Close drawer
  }

  Future<void> _fetchInitialGreeting() async {
    // If online, request a greeting from Gemini; otherwise start empty
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) return;

      final greeting = await geminiService.generateResponse('Bonjour');
      if (greeting.isNotEmpty) {
        _messages.add(
          Message(
            id: DateTime.now().toString(),
            content: greeting,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (_) {
      // ignore errors for initial greeting
    }
  }

  void _sendMessage({String? cacheKey}) {
    if (_messageController.text.isEmpty) return;

    final userMessage = Message(
      id: DateTime.now().toString(),
      content: _messageController.text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Persist user message to chat history
    () async {
      await chatHistoryService.addMessageToCurrentSession(
        ChatMessage(
          role: 'user',
          content: userMessage.content,
          timestamp: userMessage.timestamp,
        ),
      );

      try {
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity == ConnectivityResult.none) {
          final offlineMsg = Message(
            id: DateTime.now().toString(),
            content:
                'Vous êtes hors-ligne — le chat IA nécessite une connexion internet.',
            isUser: false,
            timestamp: DateTime.now(),
          );

          if (mounted) {
            setState(() {
              _messages.add(offlineMsg);
              _isLoading = false;
            });
            _scrollToBottom();
          }
          return;
        }

        String response;
        if (cacheKey != null) {
          response = await geminiService.getAdviceWithCache(
            userMessage.content,
            cacheKey,
          );
        } else {
          // Préparer l'historique du chat pour le contexte
          final chatHistoryForContext = _messages
              .map((msg) => {
                    'role': msg.isUser ? 'user' : 'assistant',
                    'content': msg.content,
                  })
              .toList();
          
          response = await geminiService.generateResponseWithContext(
            userMessage.content,
            chatHistoryForContext,
          );
        }
        final aiResponse = Message(
          id: DateTime.now().toString(),
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
        );

        // Persist AI response
        await chatHistoryService.addMessageToCurrentSession(
          ChatMessage(
            role: 'assistant',
            content: response,
            timestamp: aiResponse.timestamp,
          ),
        );

        // Update session title if this is the first response
        final current = chatHistoryService.getCurrentSession();
        if (current != null && current.messages.length == 2) {
          final titlePreview =
              userMessage.content.length > 30
                  ? '${userMessage.content.substring(0, 30)}...'
                  : userMessage.content;
          await chatHistoryService
              .updateCurrentSessionTitle(titlePreview);
        }

        if (mounted) {
          setState(() {
            _messages.add(aiResponse);
            _isLoading = false;
          });
          _scrollToBottom();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.add(
              Message(
                id: DateTime.now().toString(),
                content:
                    'Erreur lors de la communication avec le service IA: $e',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            _isLoading = false;
          });
          _scrollToBottom();
        }
      }
    }();
  }

  // Removed predefined responses: Gemini is now the only source of replies when online.

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppConstants.animationNormal,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    context.read<ThemeProvider>();

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: CustomAppBar(
        title: 'Green Bot',
        isDarkMode: isDarkMode,
        showProfileIcon: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _startNewChat,
            tooltip: 'Nouvelle discussion',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: isDarkMode
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          child: Column(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? AppColors.darkGradient
                      : AppColors.lightGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, color: Colors.white, size: 28),
                    const SizedBox(height: 8),
                    const Text(
                      'Historique',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _sessions.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune discussion',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _sessions.length,
                        itemBuilder: (context, idx) {
                          final session = _sessions[idx];
                          final isActive =
                              chatHistoryService.getCurrentSession()?.id ==
                                  session.id;
                          return ListTile(
                            title: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            subtitle: Text(
                              '${session.messages.length} messages',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () => _loadSession(session.id),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                chatHistoryService.deleteSession(session.id);
                                _loadSessions();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      body: GradientBackground(
        isDarkMode: isDarkMode,
        opacity: 0.08,
        child: SafeArea(
          child: Column(
            children: [
              // Messages List
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: isDarkMode
                                  ? AppColors.darkHint
                                  : AppColors.lightHint,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun message',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const SmoothScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingMedium,
                        ),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: AppConstants.paddingMedium,
                                  top: AppConstants.paddingSmall,
                                  bottom: AppConstants.paddingSmall,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Green Bot écrit...',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? AppColors.darkHint
                                            : AppColors.lightHint,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                      ),
                                    ).animate(onPlay: (c) => c.repeat())
                                     .fadeIn(duration: 500.ms)
                                     .then()
                                     .fadeOut(duration: 500.ms),
                                  ],
                                ),
                              ),
                            );
                          }

                          return AnimatedChatMessage(
                            text: _messages[index].content,
                            isUser: _messages[index].isUser,
                            index: index,
                            imageUrl: _messages[index].imageUrl,
                            avatarUrl: _messages[index].isUser 
                                ? context.read<AuthProvider>().currentUser?.avatarUrl 
                                : null,
                          ).slideUpIn(delayMs: index * 50);
                        },
                      ),
              ),

              // Input Area
              GradientCard(
                isDarkMode: isDarkMode,
                opacity: 0.08,
                borderRadius: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingSmall,
                ),
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isLoading,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Écrivez un message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusMedium,
                            ),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? const Color.fromRGBO(66, 66, 66, 0.3)
                                  : const Color.fromRGBO(224, 224, 224, 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusMedium,
                            ),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? const Color.fromRGBO(27, 94, 32, 0.3)
                              : const Color.fromRGBO(232, 245, 233, 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    BounceAnimation(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: isDarkMode
                              ? AppColors.darkGradient
                              : AppColors.lightGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : _sendMessage,
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
