import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'article_list_screen.dart';
import 'product_screen.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final double sideInset = 20.w;
    final double barHeight = 64.h;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          title: (_selectedIndex == 0)
              ? Image.asset('assets/images/nubdexchange_logo.jpg', scale: 11.sp)
              : CustomText(
                  text: (_selectedIndex == 1)
                      ? 'Articles'
                      : (_selectedIndex == 2) ? 'Profile' : 'Home',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: Stack(
          children: [
            PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              children: <Widget>[
                const ProductScreen(),
                const ArticleListScreen(),
                Center(
                  child: CustomText(
                    text: 'Profile page coming soon',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              onPageChanged: (page) {
                setState(() {
                  _selectedIndex = page;
                });
              },
            ),
            Positioned(
              left: sideInset,
              bottom: 16.h,
              child: FloatingActionButton(
                heroTag: 'chatFab',
                onPressed: _openChat,
                backgroundColor: const Color(0xFFE4A800),
                foregroundColor: Colors.white,
                elevation: 4,
                tooltip: 'Chat',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Icon(Icons.chat_bubble_outline, size: 24.sp),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomNavigationBar(
          height: barHeight,
          children: [
            _NavItem(
              icon: Icons.shop_2,
              label: 'Shop',
              selected: _selectedIndex == 0,
              onTap: () => _onTappedBar(0),
            ),
            _NavItem(
              icon: Icons.article,
              label: 'Articles',
              selected: _selectedIndex == 1,
              onTap: () => _onTappedBar(1),
            ),
            _NavItem(
              icon: Icons.person,
              label: 'Profile',
              selected: _selectedIndex == 2,
              onTap: () => _onTappedBar(2),
            ),
          ],
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }

  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => const _ChatSheet(),
    );
  }
}

class _ChatSheet extends StatefulWidget {
  const _ChatSheet();

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _messageController = TextEditingController();
  final List<String> _buyerMessages = ['Hi! Is the NU shirt still available?'];
  final List<String> _sellerMessages = [
    'Hello! Yes, it is available.',
    'You can add it to your cart whenever you are ready.',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _buyerMessages.add(message);
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final messages = <({String text, bool isBuyer})>[
      (text: _buyerMessages[0], isBuyer: true),
      ..._sellerMessages.map(
        (message) => (text: message, isBuyer: false),
      ),
      ..._buyerMessages.skip(1).map(
        (message) => (text: message, isBuyer: true),
      ),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: 440.h,
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.storefront_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NU BD Exchange Seller',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Usually replies quickly',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(height: 24.h),
            Expanded(
              child: ListView.separated(
                itemCount: messages.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _ChatBubble(
                    message: message.text,
                    isBuyer: message.isBuyer,
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Write a message',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14.w),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton.filled(
                  onPressed: _sendMessage,
                  tooltip: 'Send message',
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isBuyer});

  final String message;
  final bool isBuyer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isBuyer
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foreground = isBuyer
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Align(
      alignment: isBuyer ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isBuyer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            isBuyer ? 'You' : 'Seller',
            style: TextStyle(
              fontSize: 11.sp,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          Container(
            constraints: BoxConstraints(maxWidth: 270.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Text(message, style: TextStyle(color: foreground, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar({
    required this.height,
    required this.children,
  });

  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      elevation: 8,
      shadowColor: colorScheme.shadow.withOpacity(0.28),
      child: SizedBox(
        height: height,
        child: Row(
          children: children
              .map((child) => Expanded(child: Center(child: child)))
              .toList(),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: selected ? colorScheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
