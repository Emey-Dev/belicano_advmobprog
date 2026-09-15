import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';

import '../services/cart_service.dart';
import '../services/user_service.dart';

import '../widgets/custom_text.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final Future<List<Product>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _userId = currentUserId;

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadCartProducts();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = await UserService().getUser();
    if (mounted && user.id != 0) setState(() => _userId = user.id);
  }

  Future<List<Product>> _loadCartProducts() async {
    final carts = await CartService().getAllCarts();
    return carts
        .expand((cart) => cart.products)
        .map(_cartProductToProduct)
        .toList();
  }

  Product _cartProductToProduct(CartProduct cartProduct) {
    return Product(
      id: cartProduct.id,
      title: cartProduct.title,
      description: 'This product is currently listed in a cart.',
      category: 'Cart product',
      price: cartProduct.price,
      discountPercentage: cartProduct.discountPercentage,
      rating: 0,
      stock: cartProduct.quantity,
      tags: const [],
      brand: 'DummyJSON',
      sku: 'CART-${cartProduct.id}',
      weight: 0,
      dimensions: ProductDimensions(length: 0, width: 0, height: 0),
      warrantyInformation: 'Please ask the seller for warranty details.',
      shippingInformation: 'Please ask the seller about delivery.',
      availabilityStatus: 'Available in cart',
      reviews: const [],
      returnPolicy: 'Please ask the seller about returns.',
      minimumOrderQuantity: 1,
      meta: ProductMeta(createdAt: '', updatedAt: '', barcode: '', qrCode: ''),
      images: [cartProduct.thumbnail],
      thumbnail: cartProduct.thumbnail,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.2, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products',
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
                ),
                SizedBox(width: 12.w),
                Material(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12.r),
                  child: IconButton(
                    tooltip: 'Cart',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CartScreen(userId: _userId)),
                    ),
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 24.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.r),
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: CustomText(
                      text: 'Error: ${snapshot.error}',
                      fontSize: 16.sp,
                    ),
                  );
                }

                final products = snapshot.data ?? [];
                final filteredProducts = _searchQuery.isEmpty
                    ? products
                    : products.where((product) {
                        final query = _searchQuery.toLowerCase();
                        return product.title.toLowerCase().contains(query) ||
                            product.description.toLowerCase().contains(query) ||
                            product.brand.toLowerCase().contains(query) ||
                            product.category.toLowerCase().contains(query);
                      }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: CustomText(
                      text: 'No products found.',
                      fontSize: 14.sp,
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsScreen(product: product, userId: _userId),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildProductImage(product.thumbnail),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: product.title,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    text: product.brand,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    text: '₱${product.price.toStringAsFixed(2)}',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    text: '${product.rating.toStringAsFixed(1)} ⭐ • ${product.stock} in stock',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Icon(Icons.image, size: 24.sp),
    );
  }
}
