import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

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
    _fetchInitialGreeting();
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

  void _sendMessage() {
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

        final response = await geminiService.generateResponse(
          userMessage.content,
        );
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
      appBar: AppBar(
        title: const Text('Green Bot'),
        backgroundColor: isDarkMode
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        elevation: 0,
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
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? AppColors.darkGradient
                      : AppColors.lightGradient,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.history, color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Historique des discussions',
                      style: TextStyle(color: Colors.white, fontSize: 18),
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
                                ),
                                child: ShimmerLoading(
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDarkMode
                                          ? AppColors.darkSurface
                                          : AppColors.lightSurface,
                                      border: Border.all(
                                        color: isDarkMode
                                            ? AppColors.darkPrimary
                                            : AppColors.lightPrimary,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                isDarkMode
                                                    ? AppColors.darkPrimary
                                                    : AppColors.lightPrimary,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return AnimatedChatMessage(
                            text: _messages[index].content,
                            isUser: _messages[index].isUser,
                            index: index,
                            imageUrl: _messages[index].imageUrl,
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
