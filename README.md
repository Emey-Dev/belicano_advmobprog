# NU BD Exchange

Activity 3 - ADVMOBPROG - Mark Antonio A. Belicano. This app gets product and cart data from DummyJSON using the API host saved in `assets/.env`.

## Setup and run

1. When starting the activity, I used flutter clean, then flutter pub get after finishing all the changes.
2. Make sure assets/.env has the API host:
   HOST=https://dummyjson.com
3. Run the app using flutter run.

The app has fallback mock products and cart items in case a request fails.

## Enhancement 1 - Product browsing and details

Enhancement 1 adds the product browsing flow. ProductScreen gets the carts from `GET /carts`, then collects all the products inside those carts and shows them in a searchable grid. Tapping a product opens ProductDetailsScreen.

The cart API gives basic product information only, such as the name, price, quantity, discount, and image. ProductScreen fills in simple default text for missing information so the existing detail screen can still be used.

The details screen shows product info like the name, description, category, price, stock, and shipping. If the details screen is opened from the product list, it shows the **Buy Now** and **Add to Cart** buttons. Cart items can also be opened in the details screen just to view them, and in that case showAddToCart is set to false so the user can't add the same item again from the Cart screen.

## Enhancement 2 - Navigation, responsive UI, and theme support
- The home screen has three main destinations: Shop, Articles, and Profile.
- The shop has a search field and a cart icon beside it so the user can quickly go to the cart.
- The chat button floats above the lower-left part of the navigation bar.
- The bottom navigation has three equally spaced, theme-aware items with a clear selected state.
- The Settings screen can switch between light and dark mode using ThemeProvider and Provider.
- UI sizes use flutter_screenutil so spacing and text scale better across different device sizes.

## Enhancement 3 - Cart API and cart management

Enhancement 3 connects the cart to DummyJSON and adds cart management features.

### Cart model

lib/models/cart_model.dart maps the cart response into three models:

- Cart holds the cart metadata, totals, userId, and the products list.
- CartProduct represents one item in the cart, including quantity, price, totals, discount, and thumbnail.
- CartProductInput is a simple model used for write requests, since DummyJSON only needs a product id and quantity

The model also has immutable helper methods:

- Cart.copyWithProducts(...) makes a new cart and recalculates its totals and total quantity.
- CartProduct.copyWithQuantity(...) makes an updated line item and recalculates its totals.

This way, UI state updates stay predictable, since the screen just replaces the data with a newly computed cart instead of directly changing the model fields.

### Cart service

lib/services/cart_service.dart is the API layer. It reads HOST from assets/.env through constants.dart, then uses these endpoints:

| Method | Endpoint | Purpose |
| --- | --- | --- |
| GET | /carts | Load all carts |
| GET | /carts/{id} | Load one cart by ID |
| GET | /carts/user/{userId} | Load carts for the current user |
| POST | /carts/add | Simulate adding product IDs and quantities |
| PUT | /carts/{id} | Simulate quantity updates/removals |
| DELETE | /carts/{id} | Simulate checkout/cart deletion |

DummyJSON only simulates write requests and doesn't actually save them. Because of this, CartService keeps a small in-memory session cache based on user ID. After an item is added, the cache is what gets returned on the next cart loads, so the item stays visible while going through the app. This cache resets once the app is restarted.

### How the cart screen, service, and model work together

```text
ProductDetailsScreen
  -> CartService.addToCart(currentUserId, product ID + quantity)
  -> DummyJSON POST /carts/add
  -> CartService session cache

CartScreen
  -> CartService.getCartByUser(currentUserId)
  -> Cart model and CartProduct list
  -> ListView renders each CartProduct

Quantity controls / swipe to remove
  -> Cart.copyWithProducts and CartProduct.copyWithQuantity (instant UI state)
  -> CartService.updateCart(...) sends PUT /carts/{id}
  -> session cache stays in sync
```

