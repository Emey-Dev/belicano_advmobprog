import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'article_list_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
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
    final double barHeight = 64.h;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: _selectedIndex == 1
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                elevation: 2,
                title: (_selectedIndex == 0)
                    ? Image.asset(
                        'assets/images/nubdexchange_logo.png',
                        scale: 11.sp,
                      )
                    : CustomText(
                        text: (_selectedIndex == 2)
                            ? 'Articles'
                            : (_selectedIndex == 3)
                            ? 'Profile'
                            : 'Home',
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
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: const <Widget>[
            ProductScreen(),
            ChatScreen(),
            ArticleListScreen(),
            ProfileScreen(),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
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
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              selected: _selectedIndex == 1,
              onTap: () => _onTappedBar(1),
            ),
            _NavItem(
              icon: Icons.article,
              label: 'Articles',
              selected: _selectedIndex == 2,
              onTap: () => _onTappedBar(2),
            ),
            _NavItem(
              icon: Icons.person,
              label: 'Profile',
              selected: _selectedIndex == 3,
              onTap: () => _onTappedBar(3),
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
}

class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar({required this.height, required this.children});

  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final headerColor =
        Theme.of(context).appBarTheme.backgroundColor ?? colorScheme.surface;

    return Material(
      color: headerColor,
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
    final iconColor = selected ? colorScheme.onPrimary : Colors.white;
    final labelColor = selected
        ? colorScheme.primary
        : Colors.white.withValues(alpha: 0.82);

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
                  color: selected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(icon, color: iconColor, size: 22.sp),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
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
