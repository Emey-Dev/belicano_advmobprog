import 'package:belicano_advmobprog/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';
import 'product_details_screen.dart';

class CartScreen extends StatefulWidget {
  // Enhancement 3
  final int userId;
  const CartScreen({super.key, this.userId = currentUserId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _service = CartService();

  Cart? _cart; // Enhancement 3
  bool _loading = true; // Enhancement 3
  String? _error; // Enhancement 3
  final Set<int> _busy = {}; // Enhancement 3

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // Enhancement 3
  Future<void> _loadCart() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final carts = await _service.getCartByUser(widget.userId);
      setState(() {
        _cart = carts.isNotEmpty ? carts[0] : null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Enhancement 3
  Future<void> _updateQuantity(CartProduct product, int newQty) async {
    if (_cart == null) return;
    List<CartProduct> updated;
    if (newQty <= 0) {
      updated = _cart!.products.where((p) => p.id != product.id).toList();
    } else {
      updated = _cart!.products
          .map((p) => p.id == product.id ? p.copyWithQuantity(newQty) : p)
          .toList();
    }
    setState(() {
      _cart = _cart!.copyWithProducts(updated);
      _busy.add(product.id);
    });

    try {
      await _service.updateCart(
        cartId: _cart!.id,
        products: [
          CartProductInput(id: product.id, quantity: newQty <= 0 ? 0 : newQty),
        ],
        merge: true,
      );
    } catch (_) {
    } finally {
      setState(() {
        _busy.remove(product.id);
      });
    }
  }

  Future<void> _removeProduct(CartProduct product) async {
    await _updateQuantity(product, 0);
  }

  // Enhancement 3
  Future<void> _confirmOrder() async {
    if (_cart == null) return;
    final cartId = _cart!.id;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final deleted = await _service.deleteCart(cartId);
      if (mounted) Navigator.of(context).pop(); // Enhancement 3

      if (deleted.isDeleted && mounted) {
        setState(() {
          _cart = _cart!.copyWithProducts([]);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order confirmed! Your cart has been cleared.'),
            backgroundColor: Color(0xFFE4A800),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to confirm order: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 2,
        title: CustomText(
          text: 'Cart',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Enhancement 3
          IconButton(
            icon: Icon(Icons.refresh, size: 24.sp),
            tooltip: 'Refresh cart',
            onPressed: _loadCart,
          ),
          IconButton(
            icon: Icon(Icons.settings, size: 24.sp),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      // Enhancement 2
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              text: 'Failed to load cart',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 8.h),
            ElevatedButton.icon(
              onPressed: _loadCart,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_cart == null || _cart!.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64.sp,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16.h),
            CustomText(
              text: 'Your cart is empty',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 8.h),
            ElevatedButton.icon(
              onPressed: _loadCart,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
          ],
        ),
      );
    }

    final products = _cart!.products;
    final rawTotal = _cart!.total;
    final discountedTotal = _cart!.discountedTotal;
    final discountAmount = rawTotal - discountedTotal;

    return Column(
      children: [
        // Enhancement 3
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              // Enhancement 3
              return Dismissible(
                key: ValueKey(product.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.w),
                  margin: EdgeInsets.only(bottom: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
                onDismissed: (_) => _removeProduct(product),
                child: _CartItemCard(
                  product: product,
                  userId: widget.userId,
                  isBusy: _busy.contains(product.id),
                  onIncrement: () =>
                      _updateQuantity(product, product.quantity + 1),
                  onDecrement: () =>
                      _updateQuantity(product, product.quantity - 1),
                ),
              );
            },
          ),
        ),

        Container(
          color: colorScheme.surface,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(
                label: 'Subtotal:',
                value: 'PHP ${rawTotal.toStringAsFixed(2)}',
                valueColor: colorScheme.onSurface,
              ),
              SizedBox(height: 4.h),
              _SummaryRow(
                label: 'Discounted Price:',
                value: '- PHP ${discountAmount.toStringAsFixed(2)}',
                valueColor: Colors.redAccent,
              ),
              SizedBox(height: 4.h),
              _SummaryRow(
                label: 'Total:',
                value: 'PHP ${discountedTotal.toStringAsFixed(2)}',
                valueColor: const Color(0xFFE4A800),
              ),
              SizedBox(height: 4.h),
              _SummaryRow(
                label: 'Items:',
                value: '${_cart!.totalQuantity} pcs',
                valueColor: colorScheme.onSurface,
              ),
              SizedBox(height: 14.h),

              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _cart!.products.isEmpty ? null : _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE4A800),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 0,
                  ),
                  child: CustomText(
                    text: 'Confirm Order',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Enhancement 1
class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.product,
    required this.userId,
    required this.isBusy,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CartProduct product;
  final int userId;
  final bool isBusy; // Enhancement 1
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  // Enhancement 1
  Product _toProduct() => Product(
    id: product.id,
    title: product.title,
    description: 'Item from your cart.',
    category: '',
    price: product.price,
    discountPercentage: product.discountPercentage,
    rating: 0.0,
    stock: product.quantity,
    tags: const [],
    brand: '',
    sku: '',
    weight: 0.0,
    dimensions: ProductDimensions(length: 0, width: 0, height: 0),
    warrantyInformation: '',
    shippingInformation: '',
    availabilityStatus: 'In Cart',
    reviews: const [],
    returnPolicy: '',
    minimumOrderQuantity: 1,
    meta: ProductMeta(createdAt: '', updatedAt: '', barcode: '', qrCode: ''),
    images: [product.thumbnail],
    thumbnail: product.thumbnail,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      // Enhancement 1
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(
            product: _toProduct(),
            userId: userId,
            showAddToCart: false,
          ),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: _buildThumbnail(colorScheme),
            ),
            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.title,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  // Enhancement 1
                  CustomText(
                    text: 'PHP ${product.price.toStringAsFixed(2)}',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text:
                        '${product.discountPercentage.toStringAsFixed(0)}% off'
                        ' · PHP ${product.discountedTotal.toStringAsFixed(2)} total',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            isBusy
                ? SizedBox(
                    width: 32.w,
                    height: 80.w,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      GestureDetector(
                        onTap: onIncrement,
                        child: Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4A800),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      CustomText(
                        text: '${product.quantity}',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      SizedBox(height: 6.h),
                      GestureDetector(
                        onTap: onDecrement,
                        child: Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.remove,
                            color: colorScheme.onSurfaceVariant,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme colorScheme) {
    final thumb = product.thumbnail;
    if (thumb.startsWith('assets/')) {
      return Image.asset(
        thumb,
        width: 70.w,
        height: 70.w,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(colorScheme),
      );
    }
    return Image.network(
      thumb,
      width: 70.w,
      height: 70.w,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(colorScheme),
    );
  }

  Widget _placeholder(ColorScheme colorScheme) => Container(
    width: 70,
    height: 70,
    color: colorScheme.surfaceContainerHighest,
    child: Icon(Icons.image_not_supported, color: colorScheme.onSurfaceVariant),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(text: label, fontSize: 13.sp, fontWeight: FontWeight.w500),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: valueColor == cs.onSurface ? cs.onSurface : valueColor,
          ),
        ),
      ],
    );
  }
}
