import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/product_model.dart';

// Enhancement 1

class ProductService {
  Future<List<Product>> getAllProducts() async {
    try {
    if (host != null && host!.isNotEmpty) {
      final uri = Uri.parse('$host/products');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List productsJson = data['products'] ?? [];
        return productsJson.map((json) => Product.fromJson(json)).toList();
      }
      }
    } catch (_) {
      
    }

    return _mockProducts();
  }

  List<Product> _mockProducts() {
    return _mockProductsJson.map((json) => Product.fromJson(json)).toList();
  }
}

const List<Map<String, dynamic>> _mockProductsJson = [
  {
    'id': 1,
    'title': 'NU Shirt 1',
    'description':
        'Classic navy tee with National University Manila lettering and the university shield, made for students and alumni.',
    'category': 'NU Apparel',
    'price': 700,
    'discountPercentage': 0.0,
    'rating': 4.9,
    'stock': 120,
    'tags': ['nu', 'shirt', 'manila', 'apparel'],
    'brand': 'National University Manila',
    'sku': 'NU-SHIRT-01',
    'weight': 0.18,
    'dimensions': {'length': 70.0, 'width': 50.0, 'height': 1.0},
    'warrantyInformation':
        'Quality checked NU apparel with standard garment care instructions.',
    'shippingInformation':
        'Standard university store shipping in 3-4 business days.',
    'availabilityStatus': 'Available',
    'reviews': [
      {
        'rating': 5,
        'comment': 'Perfect fit and the logo is crisp.',
        'date': '2026-08-01',
        'reviewerName': 'Miguel',
        'reviewEmail': 'miguel@example.com',
      },
    ],
    'returnPolicy': 'Easy return within 14 days if unworn.',
    'minimumOrderQuantity': 1,
    'meta': {
      'createdAt': '2026-07-20',
      'updatedAt': '2026-08-02',
      'barcode': 'NU1900TS001',
      'qrCode': 'NU1900TS001',
    },
    'images': ['assets/images/nu_shirt1.jpg', 'assets/images/nu_shirt2.jpg'],
    'thumbnail': 'assets/images/nu_shirt1.jpg',
  },
  {
    'id': 2,
    'title': 'NU Shirt 2',
    'description':
        'Soft cotton tee featuring the iconic National University bulldog and bold NU 1900 text.',
    'category': 'NU Apparel',
    'price': 1100,
    'discountPercentage': 0.0,
    'rating': 4.8,
    'stock': 95,
    'tags': ['nu', 'shirt', 'bulldog', 'college'],
    'brand': 'National University Manila',
    'sku': 'NU-SHIRT-02',
    'weight': 0.17,
    'dimensions': {'length': 71.0, 'width': 51.0, 'height': 1.0},
    'warrantyInformation': 'Approved NU merchandise with comfortable fabric.',
    'shippingInformation': 'Ships within 3 business days.',
    'availabilityStatus': 'Available',
    'reviews': [
      {
        'rating': 5,
        'comment': 'Feels great and looks official.',
        'date': '2026-08-03',
        'reviewerName': 'Carla',
        'reviewEmail': 'carla@example.com',
      },
    ],
    'returnPolicy': '14-day return for defects and sizing issues.',
    'minimumOrderQuantity': 1,
    'meta': {
      'createdAt': '2026-07-22',
      'updatedAt': '2026-08-03',
      'barcode': 'NU1900TS002',
      'qrCode': 'NU1900TS002',
    },
    'images': ['assets/images/nu_shirt2.jpg', 'assets/images/nu_hoodie.jpg'],
    'thumbnail': 'assets/images/nu_shirt2.jpg',
  },
  {
    'id': 3,
    'title': 'Nu Hoodie',
    'description':
        'Warm navy hoodie with the NU logo and university colors, ideal for chilly campus mornings.',
    'category': 'NU Apparel',
    'price': 900,
    'discountPercentage': 0.0,
    'rating': 4.7,
    'stock': 68,
    'tags': ['nu', 'hoodie', 'manila', 'winter'],
    'brand': 'National University Manila',
    'sku': 'NU-HOODIE-01',
    'weight': 0.42,
    'dimensions': {'length': 75.0, 'width': 55.0, 'height': 2.0},
    'warrantyInformation':
        'University-licensed hoodie with soft brushed interior.',
    'shippingInformation': 'Delivered in 4 business days.',
    'availabilityStatus': 'Available',
    'reviews': [
      {
        'rating': 5,
        'comment': 'Cozy and looks exactly like the official campus hoodie.',
        'date': '2026-08-05',
        'reviewerName': 'Jessa',
        'reviewEmail': 'jessa@example.com',
      },
    ],
    'returnPolicy': '14-day return policy for unworn items.',
    'minimumOrderQuantity': 1,
    'meta': {
      'createdAt': '2026-07-25',
      'updatedAt': '2026-08-05',
      'barcode': 'NU1900HD001',
      'qrCode': 'NU1900HD001',
    },
    'images': ['assets/images/nu_hoodie.jpg', 'assets/images/nu_shirt1.jpg'],
    'thumbnail': 'assets/images/nu_hoodie.jpg',
  },
];
