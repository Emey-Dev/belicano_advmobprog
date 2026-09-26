import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_details_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  String? _currentUserEmail;
  String? _currentUserId;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    final userData = await _userService.getUserData();
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    setState(() {
      _currentUserEmail = firebaseUser?.email ?? userData['email']?.toString();
      _currentUserId = firebaseUser?.uid;
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 23.w),
              child: TextField(
                controller: _searchChatController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() => _searchText = value.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search chat...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: (_searchChatController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.cancel),
                          onPressed: () {
                            setState(() {
                              _searchChatController.clear();
                              _searchText = '';
                            });
                          },
                        )
                      : null),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // Users Stream
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  );
                }
                if (snapshot.hasError) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: Center(
                      child: CustomText(
                        text: 'Error loading users',
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: Center(
                      child: CustomText(
                        text: 'No users found',
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }

                final users = snapshot.data!.where((user) {
                  final userId = (user['uid'] ?? '').toString();
                  final userEmail = (user['email'] ?? '').toString();
                  final userName = [
                    user['firstName'],
                    user['lastName'],
                    user['username'],
                  ].whereType<String>().join(' ');
                  final matchesCurrentUser =
                      _currentUserId != null && userId == _currentUserId;
                  final matchesSearch =
                      _searchText.isEmpty ||
                      userName.toLowerCase().contains(_searchText) ||
                      userEmail.toLowerCase().contains(_searchText);

                  return !matchesCurrentUser && matchesSearch;
                }).toList();

                if (users.isEmpty) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: Center(
                      child: CustomText(
                        text: 'No users match your search',
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final displayName = [user['firstName'], user['lastName']]
                        .whereType<String>()
                        .map((name) => name.trim())
                        .where((name) => name.isNotEmpty)
                        .join(' ');
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              currentUserEmail: _currentUserEmail ?? '',
                              tappedUser: user,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: CustomText(
                              text:
                                  user['firstName'] != null &&
                                      user['firstName'].toString().isNotEmpty
                                  ? user['firstName'][0].toUpperCase()
                                  : '?',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          title: CustomText(
                            text: displayName.isNotEmpty
                                ? displayName
                                : (user['username'] ?? 'Unknown').toString(),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: CustomText(
                            text: user['email'] ?? 'No email',
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
