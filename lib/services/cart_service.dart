import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart_model.dart';

  // Ench 3
// Ench 3

class CartService {
  static final Map<int, Cart> _sessionCarts = {};

  Future<List<Cart>> getAllCarts() async {
    try {
      final res = await http.get(Uri.parse('$host/carts'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['carts'] as List? ?? [];
        return list.map((j) => Cart.fromJson(j)).toList();
      }
    } catch (_) {}
    return [_buildMockCart()];
  }

  Future<Cart> getCartById(int id) async {
    try {
      final res = await http.get(Uri.parse('$host/carts/$id'));
      if (res.statusCode == 200) {
        return Cart.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return _buildMockCart();
  }

  // Ench 3
  Future<List<Cart>> getCartByUser(int userId) async {
    final sessionCart = _sessionCarts[userId];
    if (sessionCart != null) return [sessionCart];

    try {
      final res =
          await http.get(Uri.parse('$host/carts/user/$userId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['carts'] as List? ?? [];
        if (list.isNotEmpty) {
          final cart = Cart.fromJson(list[0]);
          _sessionCarts[userId] = cart;
          return [cart];
        }
      }
    } catch (_) {}
    return [_buildMockCart()];
  }

    // Ench 3
  Future<Cart> addToCart({
    required int userId,
    required List<CartProductInput> products,
  }) async {
    final res = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': products.map((p) => p.toJson()).toList(),
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final addedCart = Cart.fromJson(jsonDecode(res.body));
      final existingCart = _sessionCarts[userId];
      final sessionCart = existingCart == null
          ? addedCart
          : _mergeProducts(existingCart, addedCart.products);
      _sessionCarts[userId] = sessionCart;
      return sessionCart;
    }
    throw Exception('Failed to add to cart (${res.statusCode})');
  }


  Future<Cart> updateCart({
    required int cartId,
    required List<CartProductInput> products,
    bool merge = true,
  }) async {
    final res = await http.put(
      Uri.parse('$host/carts/$cartId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'merge': merge,
        'products': products.map((p) => p.toJson()).toList(),
      }),
    );
    if (res.statusCode == 200) {
      final cart = Cart.fromJson(jsonDecode(res.body));
      int? userId;
      for (final entry in _sessionCarts.entries) {
        if (entry.value.id == cartId) {
          userId = entry.key;
          break;
        }
      }
      if (userId != null) {
        final currentCart = _sessionCarts[userId]!;
        final updatedProducts = [...currentCart.products];
        for (final input in products) {
          final index = updatedProducts.indexWhere((item) => item.id == input.id);
          if (input.quantity <= 0) {
            updatedProducts.removeWhere((item) => item.id == input.id);
          } else if (index >= 0) {
            updatedProducts[index] = updatedProducts[index].copyWithQuantity(input.quantity);
          }
        }
        _sessionCarts[userId] = currentCart.copyWithProducts(updatedProducts);
      }
      return cart;
    }
    throw Exception('Failed to update cart (${res.statusCode})');
  }

  Future<Cart> deleteCart(int cartId) async {
    final res = await http.delete(Uri.parse('$host/carts/$cartId'));
    if (res.statusCode == 200) {
      final cart = Cart.fromJson(jsonDecode(res.body));
      _sessionCarts.removeWhere((_, value) => value.id == cartId);
      return cart;
    }
    throw Exception('Failed to delete cart (${res.statusCode})');
  }

  Cart _buildMockCart() {
    final products = _mockItems.map((p) {
      final price = (p['price'] as num).toDouble();
      const qty = 1;
      return CartProduct(
        id: p['id'] as int,
        title: p['title'] as String,
        price: price,
        quantity: qty,
        total: price * qty,
        discountPercentage: 0.0,
        discountedTotal: price * qty,
        thumbnail: p['thumbnail'] as String,
      );
    }).toList();

    final total = products.fold(0.0, (s, p) => s + p.total);
    return Cart(
      id: 1,
      products: products,
      total: total,
      discountedTotal: total,
      userId: 1,
      totalProducts: products.length,
      totalQuantity: products.length,
    );
  }

  Cart _mergeProducts(Cart cart, List<CartProduct> productsToAdd) {
    final products = [...cart.products];
    for (final product in productsToAdd) {
      final index = products.indexWhere((item) => item.id == product.id);
      if (index == -1) {
        products.add(product);
      } else {
        products[index] = products[index].copyWithQuantity(
          products[index].quantity + product.quantity,
        );
      }
    }
    return cart.copyWithProducts(products);
  }
}

// Ench 3
const _mockItems = [
  {'id': 1, 'title': 'NU Shirt 1',  'price': 700,  'thumbnail': 'assets/images/nu_shirt1.jpg'},
  {'id': 2, 'title': 'NU Shirt 2',  'price': 1100, 'thumbnail': 'assets/images/nu_shirt2.jpg'},
  {'id': 3, 'title': 'Nu Hoodie',   'price': 900,  'thumbnail': 'assets/images/nu_hoodie.jpg'},
];
