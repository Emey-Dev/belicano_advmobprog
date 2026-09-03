import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/custom_text.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _articles = [
    {
      'title': 'ADVMOBPROG LABACT1',
      'description': 'Make a UI for mobile using Figma.',
    },
    {
      'title': 'ADVMOBPROG LABACT2',
      'description': 'Make buttons functional for labact1.',
    },
    {
      'title': 'ADVMOBPROG LABACT3',
      'description': 'Create a database.',
    },
    {
      'title': 'ADVMOBPROG LABACT4',
      'description': 'Create a backend side for the mobile.',
    },
    {
      'title': 'ADVMOBPROG LABACT5',
      'description': 'Connect the web and mobile.',
    },
  ];
  String _searchQuery = '';

  List<Map<String, String>> get _filteredArticles {
    if (_searchQuery.isEmpty) {
      return _articles;
    }
    return _articles.where((article) {
      final title = article['title']!.toLowerCase();
      final description = article['description']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final articles = _filteredArticles;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search articles',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: articles.isEmpty
                  ? Center(
                      child: CustomText(
                        text: 'No articles match your search.',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : ListView.separated(
                      itemCount: articles.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final article = articles[index];
                        return Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: article['title'] ?? '',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(height: 6.h),
                              CustomText(
                                text: article['description'] ?? '',
                                fontSize: 14.sp,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
