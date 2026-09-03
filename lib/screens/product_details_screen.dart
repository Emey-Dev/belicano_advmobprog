import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  final bool showAddToCart;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.showAddToCart = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: product.title,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: _buildProductImage(product.thumbnail),
              ),
              SizedBox(height: 16.h),
              CustomText(
                text: product.title,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: product.brand,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: 'PHP ${product.price.toStringAsFixed(2)}',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  CustomText(
                    text: '${product.rating.toStringAsFixed(1)} ⭐',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildInfoTile('Category', product.category),
              SizedBox(height: 8.h),
              _buildInfoTile('Availability', product.availabilityStatus),
              SizedBox(height: 8.h),
              _buildInfoTile('Stock', product.stock.toString()),
              SizedBox(height: 8.h),
              _buildInfoTile('SKU', product.sku),
              SizedBox(height: 14.h),
              CustomText(
                text: 'Description',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: product.description,
                fontSize: 14.sp,
                fontWeight: FontWeight.normal,
              ),
              // SizedBox(height: 16.h),
              // _buildFeatureRow('Weight', '${product.weight} kg'),
              // SizedBox(height: 8.h),
              // _buildFeatureRow(
              //   'Dimensions',
              //   '${product.dimensions.length} x ${product.dimensions.width} x ${product.dimensions.height} cm',
              // ),
              // SizedBox(height: 16.h),
              // _buildSectionTitle('Shipping'),
              // CustomText(
              //   text: product.shippingInformation,
              //   fontSize: 14.sp,
              //   fontWeight: FontWeight.normal,
              // ),
              // SizedBox(height: 16.h),
              // _buildSectionTitle('Warranty'),
              // CustomText(
              //   text: product.warrantyInformation,
              //   fontSize: 14.sp,
              //   fontWeight: FontWeight.normal,
              // ),
              // SizedBox(height: 16.h),
              // _buildSectionTitle('Return policy'),
              // CustomText(
              //   text: product.returnPolicy,
              //   fontSize: 14.sp,
              //   fontWeight: FontWeight.normal,
              // ),
              SizedBox(height: 24.h),
              // Ench 1
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: () {},
                  child: CustomText(
                    text: 'Buy Now',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (showAddToCart) ...[
                SizedBox(height: 12.h),
                // Ench 3
                SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await CartService().addToCart(
                          userId: currentUserId,
                          products: [
                            CartProductInput(id: product.id, quantity: 1),
                          ],
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '"${product.title}" added to cart!',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFFE4A800),
                            ),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add to cart.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: CustomText(
                      text: 'Add to Cart',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE4A800),
                      side: const BorderSide(
                        color: Color(0xFFE4A800),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(text: title, fontSize: 14.sp, fontWeight: FontWeight.w500),
        CustomText(text: value, fontSize: 14.sp, fontWeight: FontWeight.normal),
      ],
    );
  }

  Widget _buildFeatureRow(String title, String value) {
    return Builder(
      builder: (context) => Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: CustomText(
              text: '$title: $value',
              fontSize: 13.sp,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return CustomText(
      text: title,
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: double.infinity,
        height: 220.h,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      imagePath,
      width: double.infinity,
      height: 220.h,
      fit: BoxFit.cover,
      errorBuilder: (context, __, ___) => Container(
        height: 220.h,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(Icons.image, size: 48.sp),
      ),
    );
  }
}
