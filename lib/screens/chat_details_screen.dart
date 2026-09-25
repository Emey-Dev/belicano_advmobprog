import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:belicano_advmobprog/widgets/custom_text.dart';

import '../services/chat_service.dart';

final ChatService chatService = ChatService();

const _chatNavy = Color(0xFF0B1F3A);
const _chatGold = Color(0xFFE4A800);

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;
  bool _isSending = false;
  Timestamp? _sendingStartedAt;
  String? _pendingMessage;
  Timer? _typingTimer;
  bool _typingSent = false;

  static const _postSendDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    final receiverId = (widget.tappedUser['uid'] ?? '').toString();
    if (_typingSent) {
      unawaited(chatService.setTyping(receiverId, false));
    }
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onTypingChanged(String receiverId, String value) {
    _typingTimer?.cancel();
    final isTyping = value.trim().isNotEmpty;

    if (isTyping && !_typingSent) {
      _typingSent = true;
      unawaited(chatService.setTyping(receiverId, true));
    } else if (!isTyping && _typingSent) {
      _typingSent = false;
      unawaited(chatService.setTyping(receiverId, false));
    }

    if (isTyping) {
      _typingTimer = Timer(const Duration(milliseconds: 1200), () {
        if (_typingSent) {
          _typingSent = false;
          unawaited(chatService.setTyping(receiverId, false));
        }
      });
    }
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _sendingStartedAt = Timestamp.now();
      _pendingMessage = text;
    });

    try {
      await chatService.sendMessage(receiverId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }

      await Future.delayed(_postSendDelay);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingStartedAt = null;
          _pendingMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName = (widget.tappedUser['firstName'] ?? '').toString();
    final tappedUserImage = (widget.tappedUser['image'] ?? '').toString();
    final tappedUserInitial = tappedUserName.trim().isEmpty
        ? '?'
        : tappedUserName.trim()[0].toUpperCase();

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;
        final colors = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: _chatNavy,
            foregroundColor: Colors.white,
            titleSpacing: 8,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: _chatGold,
                  backgroundImage: tappedUserImage.isNotEmpty
                      ? NetworkImage(tappedUserImage)
                      : null,
                  child: tappedUserImage.isEmpty
                      ? Text(
                          tappedUserInitial,
                          style: TextStyle(
                            color: _chatNavy,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: CustomText(
                    text: tappedUserName.isEmpty ? 'Chat' : tappedUserName,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            color: colors.surface,
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: chatService.getMessage(currentUserId, tappedUserId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading messages: ${snapshot.error}',
                          ),
                        );
                      }

                      List<QueryDocumentSnapshot> docs =
                          snapshot.data?.docs ?? [];
                      if (snapshot.hasData) {
                        unawaited(
                          chatService.markMessagesSeen(
                            currentUserId,
                            tappedUserId,
                          ),
                        );
                      }

                      // hide my just-sent messages until delay completes
                      if (_isSending && _sendingStartedAt != null) {
                        docs = docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          final senderId = (data['senderId'] ?? '').toString();
                          final ts = data['timestamp'];
                          if (senderId != currentUserId) return true;
                          if (ts is Timestamp) {
                            return ts.compareTo(_sendingStartedAt!) < 0;
                          }
                          return true;
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        if (!_isSending) {
                          return const Center(child: Text('No messages yet'));
                        }
                      }

                      return ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 14.h,
                        ),
                        itemCount: docs.length + (_isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isSending && index == 0) {
                            return _MessageBubble(
                              key: const ValueKey('pending-message'),
                              text: _pendingMessage ?? '',
                              isMine: true,
                              status: _MessageStatus.sending,
                            );
                          }

                          final documentIndex = index - (_isSending ? 1 : 0);
                          final data =
                              docs[documentIndex].data()
                                  as Map<String, dynamic>;
                          final msgText = (data['message'] ?? '').toString();
                          final senderId = (data['senderId'] ?? '').toString();
                          final isMe = senderId == currentUserId;

                          return _MessageBubble(
                            key: ValueKey(docs[documentIndex].id),
                            text: msgText.isNotEmpty ? msgText : '[empty]',
                            isMine: isMe,
                            avatarUrl: tappedUserImage,
                            avatarInitial: tappedUserInitial,
                            timestamp: data['timestamp'],
                            status: isMe
                                ? _statusFromData(data)
                                : _MessageStatus.sent,
                          );
                        },
                      );
                    },
                  ),
                ),

                StreamBuilder<bool>(
                  stream: chatService.getTypingStream(
                    currentUserId,
                    tappedUserId,
                  ),
                  builder: (context, typingSnapshot) {
                    return typingSnapshot.data == true
                        ? const _TypingIndicator()
                        : const SizedBox.shrink();
                  },
                ),

                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgCtrl,
                            focusNode: _msgFocus,
                            enabled: !_isSending,
                            textInputAction: TextInputAction.send,
                            minLines: 1,
                            maxLines: 4,
                            onChanged: (value) =>
                                _onTypingChanged(tappedUserId, value),
                            onSubmitted: (_) => !_isSending
                                ? _send(currentUserId, tappedUserId)
                                : null,
                            decoration: InputDecoration(
                              hintText: _isSending
                                  ? 'Sending...'
                                  : 'Type a message',
                              filled: true,
                              fillColor: colors.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22.r),
                                borderSide: BorderSide(color: colors.outline),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _isSending
                              ? SizedBox(
                                  key: const ValueKey('sending-indicator'),
                                  height: 48.h,
                                  width: 48.w,
                                  child: const Padding(
                                    padding: EdgeInsets.all(13),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton.filled(
                                  key: const ValueKey('send-button'),
                                  style: IconButton.styleFrom(
                                    backgroundColor: _chatGold,
                                    foregroundColor: _chatNavy,
                                  ),
                                  icon: const Icon(Icons.send_rounded),
                                  tooltip: 'Send message',
                                  onPressed: () =>
                                      _send(currentUserId, tappedUserId),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _MessageStatus { sending, sent, delivered, seen }

_MessageStatus _statusFromData(Map<String, dynamic> data) {
  final status = (data['status'] ?? '').toString().toLowerCase();
  if (status == 'seen') return _MessageStatus.seen;
  if (status == 'delivered') return _MessageStatus.delivered;
  return _MessageStatus.sent;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.text,
    required this.isMine,
    required this.status,
    this.avatarUrl,
    this.avatarInitial = '?',
    this.timestamp,
  });

  final String text;
  final bool isMine;
  final _MessageStatus status;
  final String? avatarUrl;
  final String avatarInitial;
  final dynamic timestamp;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bubbleColor = isMine
        ? colors.secondary
        : colors.surfaceContainerHighest;
    final textColor = isMine ? colors.onSecondary : colors.onSurface;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((isMine ? 18 : -18) * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              CircleAvatar(
                radius: 14.r,
                backgroundColor: _chatGold,
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Text(
                        avatarInitial,
                        style: TextStyle(
                          color: _chatNavy,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 7.w),
            ],
            Container(
              margin: EdgeInsets.symmetric(vertical: 4.h),
              padding: EdgeInsets.fromLTRB(15.w, 11.h, 12.w, 8.h),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.r),
                  topRight: Radius.circular(18.r),
                  bottomLeft: Radius.circular(isMine ? 18.r : 4.r),
                  bottomRight: Radius.circular(isMine ? 4.r : 18.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: isMine
                    ? null
                    : Border.all(color: _chatGold.withOpacity(0.45)),
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: text,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.normal,
                    color: textColor,
                    textAlign: TextAlign.left,
                  ),
                  if (isMine)
                    Padding(
                      padding: EdgeInsets.only(top: 5.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (timestamp is Timestamp)
                            Text(
                              _formatMessageTime(timestamp as Timestamp),
                              style: TextStyle(
                                color: textColor.withOpacity(0.72),
                                fontSize: 10.sp,
                              ),
                            ),
                          SizedBox(width: 4.w),
                          _StatusIcon(status: status, color: textColor),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.color});

  final _MessageStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (status == _MessageStatus.sending) {
      return SizedBox(
        height: 11,
        width: 11,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
      );
    }

    return Icon(
      status == _MessageStatus.sent ? Icons.check : Icons.done_all,
      size: 14,
      color: status == _MessageStatus.seen ? _chatGold : color,
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(left: 16.w, bottom: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _chatGold.withOpacity(0.45)),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final phase = (_controller.value + index / 3) % 1;
                final scale = 0.65 + (phase < 0.5 ? phase : 1 - phase) * 0.7;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Transform.scale(
                    scale: scale,
                    child: CircleAvatar(
                      radius: 3.r,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

String _formatMessageTime(Timestamp timestamp) {
  final time = timestamp.toDate();
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
}
