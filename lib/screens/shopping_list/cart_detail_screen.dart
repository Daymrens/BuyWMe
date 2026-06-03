import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../providers/shopping_list_provider.dart';
import '../../models/shopping_item.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/animated_checkmark.dart';
import '../../widgets/simple_add_item_sheet.dart';
import '../../theme/app_theme.dart';
import '../../config/api_config.dart';

class CartDetailScreen extends ConsumerWidget {
  final String cartId;

  const CartDetailScreen({required this.cartId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListProvider);
    final cartMatches = lists.where((list) => list.id == cartId);
    if (cartMatches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('This cart no longer exists'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    final cart = cartMatches.first;
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    
    final total = cart.items.fold<double>(
      0,
      (sum, item) => sum + (item.estimatedPrice * item.quantity),
    );
    final remaining = cart.budget != null ? cart.budget! - total : null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF0A0E21), const Color(0xFF1D1F33)]
                : [const Color(0xFFF5F7FA), const Color(0xFFE8EAF6)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
              actions: [
                Hero(
                  tag: 'cart_icon_$cartId',
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showCartOptionsMenu(context, ref, cart);
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  cart.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                background: Padding(
                  padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cart.storeName != null)
                        Row(
                          children: [
                            const Icon(Icons.store, size: 16, color: AppTheme.primaryGreen),
                            const SizedBox(width: 4),
                            Text(
                              cart.storeName!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryGreen,
                                  ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Budget Summary Card
                  GlassmorphicCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem(
                              context,
                              'Spent',
                              currencyFormat.format(total),
                              Icons.shopping_cart,
                              Colors.blue,
                            ),
                            Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.3)),
                            if (cart.budget != null)
                              _buildSummaryItem(
                                context,
                                'Remaining',
                                currencyFormat.format(remaining),
                                Icons.account_balance_wallet,
                                remaining! >= 0 ? Colors.green : Colors.red,
                              )
                            else
                              _buildSummaryItem(
                                context,
                                'Items',
                                '${cart.items.length}',
                                Icons.inventory_2,
                                Colors.orange,
                              ),
                          ],
                        ),
                        if (cart.budget != null) ...[
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Budget',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    currencyFormat.format(cart.budget),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: cart.budget! > 0 ? (total / cart.budget!).clamp(0.0, 1.0) : 0,
                                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  total > cart.budget! ? Colors.red : AppTheme.primaryGreen,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                minHeight: 8,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showStockItemsSheet(context, ref, cart.id);
                        },
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('Stock Items'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (cart.items.isEmpty)
                    GlassmorphicCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_basket_outlined,
                                size: 60,
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No items yet',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add items',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...cart.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          HapticFeedback.mediumImpact();
                          ref.read(shoppingListProvider.notifier).deleteItem(cart.id, item.id);
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: GlassmorphicCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                AnimatedCheckmark(
                                  isChecked: item.isDone,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    ref.read(shoppingListProvider.notifier).toggleItem(cart.id, item.id);
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              decoration: item.isDone
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                      ),
                                      Text(
                                        '${item.quantity} ${item.unit}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(item.estimatedPrice * item.quantity),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        decoration: item.isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: index * 50))
                            .slideX(
                              begin: 0.2,
                              end: 0,
                              delay: Duration(milliseconds: index * 50),
                            ),
                      );
                    }),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showAddItemCardSheet(context, ref, cart.id);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  // New card-based Add Item UI
  void _showAddItemCardSheet(BuildContext context, WidgetRef ref, String cartId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SimpleAddItemSheet(
        cartId: cartId,
        onScanBarcode: (_, sheetRef, id) => _showBarcodeScanner(context, sheetRef, id),
        onScanReceipt: (_, sheetRef, id) => _showImageCapture(context, sheetRef, id),
      ),
    );
  }

  void _showStockItemsSheet(BuildContext context, WidgetRef ref, String cartId) {
    final stockItems = [
      {'name': 'Rice', 'unit': 'kg', 'price': 50.0},
      {'name': 'Eggs', 'unit': 'dozen', 'price': 120.0},
      {'name': 'Milk', 'unit': 'L', 'price': 90.0},
      {'name': 'Bread', 'unit': 'pcs', 'price': 50.0},
      {'name': 'Chicken', 'unit': 'kg', 'price': 200.0},
      {'name': 'Pork', 'unit': 'kg', 'price': 250.0},
      {'name': 'Fish', 'unit': 'kg', 'price': 180.0},
      {'name': 'Tomatoes', 'unit': 'kg', 'price': 60.0},
      {'name': 'Onions', 'unit': 'kg', 'price': 80.0},
      {'name': 'Potatoes', 'unit': 'kg', 'price': 70.0},
      {'name': 'Cooking Oil', 'unit': 'L', 'price': 150.0},
      {'name': 'Sugar', 'unit': 'kg', 'price': 80.0},
      {'name': 'Salt', 'unit': 'pack', 'price': 20.0},
      {'name': 'Coffee', 'unit': 'pack', 'price': 150.0},
      {'name': 'Instant Noodles', 'unit': 'pack', 'price': 15.0},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) => GlassmorphicCard(
          borderRadius: 30,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Stock Items',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to add common items',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: stockItems.length,
                  itemBuilder: (context, index) {
                    final stockItem = stockItems[index];
                    return GlassmorphicCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final item = ShoppingItem(
                            id: const Uuid().v4(),
                            productId: const Uuid().v4(),
                            name: stockItem['name'] as String,
                            quantity: 1,
                            unit: stockItem['unit'] as String,
                            estimatedPrice: stockItem['price'] as double,
                          );
                          ref.read(shoppingListProvider.notifier).addItem(cartId, item);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.shopping_basket,
                                color: AppTheme.primaryGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stockItem['name'] as String,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  Text(
                                    '1 ${stockItem['unit']}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₱${(stockItem['price'] as double).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showCartOptionsMenu(BuildContext context, WidgetRef ref, dynamic cart) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassmorphicCard(
        borderRadius: 30,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cart Options',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit, color: Colors.blue, size: 20),
              ),
              title: const Text('Edit Cart'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.pop(context);
                _showEditCartDialog(context, ref, cart);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.attach_money, color: Colors.green, size: 20),
              ),
              title: const Text('Edit Budget'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.pop(context);
                _showEditBudgetDialog(context, ref, cart);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.share, color: Colors.purple, size: 20),
              ),
              title: const Text('Share Cart'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.pop(context);
                _shareCartAsText(context, cart);
              },
            ),
            const Divider(height: 32),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete, color: Colors.red, size: 20),
              ),
              title: const Text('Delete Cart'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.pop(context);
                _showDeleteCartDialog(context, ref, cart);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditCartDialog(BuildContext context, WidgetRef ref, dynamic cart) {
    final nameController = TextEditingController(text: cart.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Cart Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Cart name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                HapticFeedback.lightImpact();
                cart.name = nameController.text;
                cart.save();
                ref.read(shoppingListProvider.notifier).refreshLists();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context, WidgetRef ref, dynamic cart) {
    final budgetController = TextEditingController(
      text: cart.budget?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Budget'),
        content: TextField(
          controller: budgetController,
          decoration: const InputDecoration(
            hintText: 'Budget amount',
            prefixText: '? ',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              final budget = budgetController.text.isEmpty
                  ? null
                  : double.tryParse(budgetController.text);
              cart.budget = budget;
              cart.save();
              ref.read(shoppingListProvider.notifier).refreshLists();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCartDialog(BuildContext context, WidgetRef ref, dynamic cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cart'),
        content: Text('Are you sure you want to delete "${cart.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(shoppingListProvider.notifier).deleteList(cart.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${cart.name} deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }


  void _shareCartAsText(BuildContext context, dynamic cart) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final total = cart.items.fold<double>(
        0, (sum, item) => sum + (item.estimatedPrice * item.quantity));

    final buffer = StringBuffer();
    buffer.writeln('?? ${cart.name}');
    if (cart.storeName != null) buffer.writeln('?? ${cart.storeName}');
    buffer.writeln('');
    for (final item in cart.items) {
      final status = item.isDone ? '?' : '?';
      buffer.writeln(
          '$status ${item.name}  �${item.quantity} ${item.unit}  ${currencyFormat.format(item.estimatedPrice * item.quantity)}');
    }
    buffer.writeln('');
    buffer.writeln('Total: ${currencyFormat.format(total)}');
    if (cart.budget != null) {
      buffer.writeln('Budget: ${currencyFormat.format(cart.budget)}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cart copied to clipboard � paste to share!'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showBarcodeScanner(BuildContext context, WidgetRef ref, String cartId) {
    final cartContext = context;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _BarcodeScannerScreen(
          onBarcodeDetected: (barcode) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (cartContext.mounted) {
                _showBarcodeResultDialog(cartContext, ref, cartId, barcode);
              }
            });
          },
        ),
      ),
    );
  }

  void _showBarcodeResultDialog(BuildContext context, WidgetRef ref, String cartId, String barcode) {
    final nameController = TextEditingController(text: 'Product $barcode');
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: '50.00');
    String selectedUnit = 'pcs';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code, color: Colors.blue),
            SizedBox(width: 8),
            Text('Scanned Product'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Barcode: $barcode', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'L', child: Text('L')),
                      ],
                      onChanged: (value) {
                        selectedUnit = value!;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₱)',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = priceController.text.trim();
              final quantity = quantityController.text.trim();
              
              // Validate inputs
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a product name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (price.isEmpty || double.tryParse(price) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid price'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (quantity.isEmpty || double.tryParse(quantity) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Create and add item
              final item = ShoppingItem(
                id: const Uuid().v4(),
                productId: const Uuid().v4(),
                name: name,
                quantity: double.parse(quantity),
                unit: selectedUnit,
                estimatedPrice: double.parse(price),
              );
              
              ref.read(shoppingListProvider.notifier).addItem(cartId, item);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name added!'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Add Item',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageCapture(BuildContext context, WidgetRef ref, String cartId) {
    final listNotifier = ref.read(shoppingListProvider.notifier);
    final cartContext = context;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ImageCaptureScreen(
          onImageCaptured: (detectedText) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (cartContext.mounted) {
                _showImageResultDialogWithNotifier(
                  cartContext,
                  ref,
                  listNotifier,
                  cartId,
                  detectedText,
                );
              }
            });
          },
        ),
      ),
    );
  }

  void _showImageResultDialogWithNotifier(
    BuildContext context,
    WidgetRef ref,
    dynamic listNotifier,
    String cartId,
    Map<String, String> detectedText,
  ) {
    final nameController = TextEditingController(text: detectedText['name'] ?? '');
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: detectedText['price'] ?? '0');
    String selectedUnit = 'pcs';
    final debugText = detectedText['_debug_text'] ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.camera_alt, color: Colors.purple),
            const SizedBox(width: 8),
            const Expanded(child: Text('Detected Product')),
            if (debugText.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () {
                  showDialog(
                    context: dialogContext,
                    builder: (context) => AlertDialog(
                      title: const Text('Detected Text'),
                      content: SingleChildScrollView(
                        child: Text(
                          debugText,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'View detected text',
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Review detected information', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                  helperText: 'Edit if needed',
                ),
                maxLines: 2,
                minLines: 1,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'g', child: Text('g')),
                        DropdownMenuItem(value: 'L', child: Text('L')),
                        DropdownMenuItem(value: 'mL', child: Text('mL')),
                        DropdownMenuItem(value: 'pack', child: Text('pack')),
                      ],
                      onChanged: (value) {
                        selectedUnit = value!;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₱)',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                  helperText: 'Edit if needed',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = priceController.text.trim();
              final quantity = quantityController.text.trim();

              // Validate name
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a product name'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }
              
              // Validate and fix price
              double parsedPrice;
              if (price.isEmpty || price == '0') {
                parsedPrice = 1.0;
              } else {
                final tryPrice = double.tryParse(price);
                if (tryPrice == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid price (numbers only)'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                parsedPrice = tryPrice;
              }

              // Validate quantity
              final parsedQuantity = double.tryParse(quantity);
              if (parsedQuantity == null || parsedQuantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }

              try {
                final item = ShoppingItem(
                  id: const Uuid().v4(),
                  productId: const Uuid().v4(),
                  name: name,
                  quantity: parsedQuantity,
                  unit: selectedUnit,
                  estimatedPrice: parsedPrice,
                );

                // Use the captured notifier instead of ref
                listNotifier.addItem(cartId, item);

                // Close dialog
                Navigator.pop(dialogContext);

                // Show success message on the parent context
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name added!'),
                    backgroundColor: AppTheme.primaryGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );

                // Capture the parent context and ref before showing the next dialog
                final parentContext = context;
                final parentRef = ref;
                final parentCartId = cartId;

                // Show dialog to choose next action
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Item Added')),
                      ],
                    ),
                    content: const Text(
                      'What would you like to do next?',
                      style: TextStyle(fontSize: 16),
                    ),
                    actionsAlignment: MainAxisAlignment.spaceBetween,
                    actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    actions: [
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          // Wait for dialog to close completely, then open camera
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (parentContext.mounted) {
                            _showImageCapture(parentContext, parentRef, parentCartId);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.primaryGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Add Another'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          // Stay on cart screen (already there)
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Go to Cart'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding item: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              minimumSize: const Size(140, 50),
              elevation: 4,
            ),
            child: const Text(
              'Add Item',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Barcode Scanner Screen
class _BarcodeScannerScreen extends StatefulWidget {
  final Function(String) onBarcodeDetected;

  const _BarcodeScannerScreen({required this.onBarcodeDetected});

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  widget.onBarcodeDetected(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryGreen, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Align barcode within frame',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// Image Capture Screen
class _ImageCaptureScreen extends StatefulWidget {
  final Function(Map<String, String>) onImageCaptured;

  const _ImageCaptureScreen({required this.onImageCaptured});

  @override
  State<_ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<_ImageCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _captureAndProcessImage() async {
    try {
      setState(() => _isProcessing = true);

      // Capture image from camera with optimized quality
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,  // ML Kit prefers compressed images
        preferredCameraDevice: CameraDevice.rear,  // Use rear camera
        maxWidth: 1200,  // Sweet spot for accuracy
        maxHeight: 1200,
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      // Try Claude Vision first if API key is configured
      Map<String, String>? result;
      if (ApiConfig.isClaudeVisionEnabled) {
        result = await _extractWithClaudeVision(image.path);
      }

      // Fallback to ML Kit + regex if Claude fails or not configured
      result ??= await _extractWithMlKit(image.path);

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        widget.onImageCaptured(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isProcessing = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    Map<String, String>? result;
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() => _isProcessing = true);
      if (ApiConfig.isClaudeVisionEnabled) {
        result = await _extractWithClaudeVision(image.path);
      }
      result ??= await _extractWithMlKit(image.path);
    } catch (e) {
      result = null;
    }
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (result != null) {
      Navigator.pop(context);
      widget.onImageCaptured(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not process image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Extract price and name using Claude Vision API
  Future<Map<String, String>?> _extractWithClaudeVision(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Detect image type
      final ext = imagePath.split('.').last.toLowerCase();
      final mediaType = ext == 'png' ? 'image/png' : 'image/jpeg';

      final response = await http.post(
        Uri.parse(ApiConfig.anthropicEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ApiConfig.anthropicApiKey,
          'anthropic-version': ApiConfig.anthropicVersion,
        },
        body: jsonEncode({
          'model': ApiConfig.claudeModel,
          'max_tokens': 256,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': '''You are a grocery price tag reader for a Philippine supermarket app.

Look at this image carefully. It may be a:
- Printed supermarket shelf label
- Handwritten price tag
- Digital/LCD price display
- Thermal receipt

Extract ONLY:
1. The product name (the item being sold, not the store name)
2. The price in Philippine Peso (PHP)

Rules:
- Product name: be specific, include brand and variant if visible (e.g. "Alaska Evaporated Milk 370ml" not just "Milk")
- Price: numeric value only, no currency symbols (e.g. "85.00" not "P85.00")
- If you see multiple prices (original + sale), use the SALE/CURRENT price
- If you cannot clearly read the name or price, use "unknown"

Respond ONLY with valid JSON, no explanation:
{"name": "product name here", "price": "00.00"}'''
                }
              ]
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'] as List?;
        if (content == null || content.isEmpty) return null;

        final textBlock = content.cast<Map<String, dynamic>>().where(
          (block) => block['type'] == 'text' && block['text'] != null,
        );
        if (textBlock.isEmpty) return null;

        final text = textBlock.first['text'] as String;

        // Strip markdown fences if present
        final clean = text
            .replaceAll(RegExp(r'```json|```'), '')
            .trim();

        final parsed = jsonDecode(clean) as Map<String, dynamic>;
        final name = (parsed['name'] as String?)?.trim() ?? '';
        final price = (parsed['price'] as String?)?.trim() ?? '';

        // Validate response is useful
        if (name.isNotEmpty &&
            name.toLowerCase() != 'unknown' &&
            price.isNotEmpty &&
            price != '0' &&
            price.toLowerCase() != 'unknown') {
          return {
            'name': name,
            'price': price,
            '_source': 'claude_vision',
            '_debug_text': 'Extracted by Claude Vision API',
          };
        }
      }

      return null; // Triggers fallback
    } catch (e) {
      return null; // Triggers fallback
    }
  }

  /// Extract price and name using ML Kit (fallback method)
  Future<Map<String, String>> _extractWithMlKit(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      // Extract text with block information for better accuracy
      String fullText = recognizedText.text;
      List<String> allLines = [];
      
      // Get text blocks for better structure
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          allLines.add(line.text);
        }
      }

      // Parse price and name with structured data
      final result = _extractPriceAndName(fullText, allLines);
      result['_source'] = 'mlkit_fallback';
      result['_debug_text'] = fullText;
      
      return result;
    } finally {
      await textRecognizer.close();
    }
  }

  Map<String, String> _extractPriceAndName(
    String text, [
    List<String>? structuredLines,
  ]) {
    final lines = structuredLines ?? text.split('\n');
    final cleanLines = lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // ----------------------------------------------------------
    // STEP 1: PRICE EXTRACTION (fixed priority order)
    // ----------------------------------------------------------

    String? extractedPrice;

    // Helper — validates a parsed price is in realistic PH range
    bool isValidPrice(double val) => val >= 5.0 && val <= 50000.0;

    // Normalize: swap comma-decimal European style → dot
    String normalizeDecimal(String s) => s.replaceAll(',', '.');

    // Priority 1 — ? or P followed by digits WITH decimals
    // e.g. ?85.00 | P 120.50 | ? 1,250.00
    final p1 = RegExp(r'[?P]\s*([\d,]{1,7}\.\d{2})', caseSensitive: false);

    // Priority 2 — keyword labels + optional ?/P + price
    // e.g. Price: 85.00 | Amount: ?120 | Total 45.50
    final p2 = RegExp(
      r'(?:price|presyo|amount|total|subtotal|halaga)[\s:]*[?P]?\s*([\d,]{1,7}(?:\.\d{2})?)',
      caseSensitive: false,
    );

    // Priority 3 — ? or P + whole number (no decimals)
    // e.g. ?85 | P 150
    final p3 = RegExp(r'[?P]\s*(\d{1,6})(?!\d|\.)', caseSensitive: false);

    // Priority 4 — number followed by peso/php suffix
    // e.g. 85 pesos | 75 php
    final p4 = RegExp(
      r'(\d{1,6}(?:\.\d{2})?)\s*(?:pesos?|php)',
      caseSensitive: false,
    );

    // Priority 5 — LAST RESORT: standalone decimal number
    // e.g. 85.00 — risky, only use if nothing else matched
    final p5 = RegExp(r'\b(\d{1,4}\.\d{2})\b');

    for (final pattern in [p1, p2, p3, p4, p5]) {
      for (final line in cleanLines) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final raw = normalizeDecimal(match.group(1)!.replaceAll(',', ''));
          final val = double.tryParse(raw);
          if (val != null && isValidPrice(val)) {
            extractedPrice = val.toStringAsFixed(2);
            break;
          }
        }
      }
      if (extractedPrice != null) break;
    }

    // ----------------------------------------------------------
    // STEP 2: PRODUCT NAME EXTRACTION (expanded for PH market)
    // ----------------------------------------------------------

    // Store names and receipt noise to skip entirely
    const skipKeywords = [
      // PH supermarkets
      'puregold', 'sm supermarket', 'sm market', 'sm hypermarket',
      'robinsons', 'landers', 'savemore', 'waltermart', 'shopwise',
      'alfamart', 'ministop', '7-eleven', 'family mart', 'lawson',
      'hypermarket', 'supermarket', 'palengke', 'bonus', 'quality products',
      // Receipt terms
      'price', 'presyo', 'amount', 'total', 'subtotal', 'change',
      'cash', 'thank you', 'receipt', 'resibo', 'date', 'time',
      'cashier', 'tin', 'vat', 'tax', 'discount', 'sale', 'promo',
      'member', 'card', 'branch', 'store', 'address', 'tel',
      'phone', 'website', 'www', 'transaction', 'ref no',
      // Common codes/barcodes patterns
      'etvwt', 'net wt', 'netwt', 'sku', 'item code', 'barcode',
    ];

    // Product words that boost score — expanded for PH grocery
    const productWords = [
      // English grocery basics
      'milk', 'bread', 'rice', 'egg', 'eggs', 'chicken', 'pork', 'beef',
      'fish', 'oil', 'sugar', 'salt', 'coffee', 'tea', 'juice', 'water',
      'butter', 'cheese', 'flour', 'vinegar', 'sauce', 'noodles', 'pasta',
      'tuna', 'sardines', 'canned', 'frozen', 'fresh', 'organic',
      'instant', 'dried', 'powder', 'condensed', 'evaporated',
      'shampoo', 'soap', 'detergent', 'lotion', 'toothpaste',
      'gelatine', 'gelatin', 'jelly', 'dessert', 'pudding',
      // Filipino food terms
      'bawang', 'sibuyas', 'kamatis', 'gata', 'bagoong', 'patis',
      'suka', 'toyo', 'asin', 'asukal', 'bigas', 'itlog', 'manok',
      'baboy', 'baka', 'isda', 'bangus', 'tilapia', 'galunggong',
      'liempo', 'lechon', 'longganisa', 'tocino', 'tapa',
      'pandesal', 'hopia', 'polvoron', 'bibingka', 'gulaman',
      // PH brands (partial — boosts if line contains these)
      'datu', 'century', 'del monte', 'ufc', 'mama sita', 'mamasita',
      'ajinomoto', 'maggi', 'knorr', 'lucky me', 'payless', 'monde',
      'rebisco', 'fita', 'skyflakes', 'milo', 'nescafe', 'kopiko',
      'bear brand', 'alaska', 'magnolia', 'selecta', 'nestea',
      'c2', 'zesto', 'grande', 'sunquick', 'tang',
      'ariel', 'tide', 'surf', 'champion', 'joy', 'domex',
      'safeguard', 'palmolive', 'head shoulders', 'pantene',
      'colgate', 'closeup', 'hapee', 'ferna', 'sarappinoy',
    ];

    // Patterns that disqualify a line as a product name
    final barcodePattern = RegExp(r'\d{12,}');
    final datePattern = RegExp(r'\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}');
    final pureDigitPattern = RegExp(r'^\d+$');
    final priceOnlyPattern = RegExp(r'^[?P\d\s.,]+$');
    final codePattern = RegExp(r'^[A-Z]{2,}\s*[.\s]*\s*\d+$', caseSensitive: false); // ETVWT. 500

    String? bestName;
    int bestScore = -999;

    for (final line in cleanLines) {
      final lower = line.toLowerCase();

      // Hard skip conditions
      if (line.length < 3) continue;
      if (barcodePattern.hasMatch(line)) continue;
      if (pureDigitPattern.hasMatch(line)) continue;
      if (priceOnlyPattern.hasMatch(line)) continue;
      if (datePattern.hasMatch(line)) continue;
      if (codePattern.hasMatch(line)) continue; // Skip code patterns like "ETVWT. 500"
      if (skipKeywords.any((kw) => lower.contains(kw))) continue;

      // Digit ratio check — skip if >60% digits (e.g. "12/25/2024", codes)
      final digitCount = line.replaceAll(RegExp(r'[^\d]'), '').length;
      if (line.isNotEmpty && digitCount / line.length > 0.6) continue;

      // Skip lines that are just numbers with dots (like "500" or "95g" alone)
      if (RegExp(r'^\d+[a-z]*$', caseSensitive: false).hasMatch(line)) continue;

      // --- Scoring ---
      int score = 0;

      // Weight/volume/unit indicators — strong signal it's a product
      if (RegExp(
        r'\b(\d+\s*(?:g|kg|ml|l|oz|lb|pcs|pc|pack|sachet|pouch|can|bottle|box|grams?|liters?|kilos?))\b',
        caseSensitive: false,
      ).hasMatch(line)) {
        score += 15;
      }

      // Mixed case = brand/product name pattern
      if (RegExp(r'[A-Z][a-z]+').hasMatch(line)) score += 5;

      // Reasonable product name length (8–60 chars is ideal)
      if (line.length >= 8 && line.length <= 60) score += 5;
      if (line.length < 8) score -= 3;
      if (line.length > 80) score -= 5;

      // Contains product keywords (any match = bonus)
      if (productWords.any((w) => lower.contains(w))) score += 10;

      // ALL CAPS short line — likely a label/header, slight penalty
      if (line == line.toUpperCase() && line.length < 20) score -= 3;

      // Has dots — brand name pattern (e.g. "S&W", "C2")
      if (line.contains('.') && !priceOnlyPattern.hasMatch(line)) score += 2;

      // Starts with capital — good sign
      if (RegExp(r'^[A-Z]').hasMatch(line)) score += 3;

      // Contains brand names - extra boost
      if (lower.contains('ferna') || lower.contains('sarappinoy')) score += 15;

      if (score > bestScore) {
        bestScore = score;
        bestName = line;
      }
    }

    // ----------------------------------------------------------
    // STEP 3: CLEAN UP NAME
    // ----------------------------------------------------------

    if (bestName != null) {
      // Remove trailing price patterns
      bestName = bestName
          .replaceAll(RegExp(r'\s*[?P]\s*\d+[.,]?\d*\s*$'), '')
          .replaceAll(RegExp(r'\s*\d+\.\d{2}\s*$'), '')
          // Remove leading/trailing non-word characters
          .replaceAll(RegExp(r'^[^\w?]+|[^\w?]+$'), '')
          .trim();

      if (bestName.isEmpty) bestName = null;
    }

    // ----------------------------------------------------------
    // RETURN
    // ----------------------------------------------------------

    return {
      'name': bestName ?? 'Unknown Product',
      'price': extractedPrice ?? '0',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Capture Price Tag'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_isProcessing ? Icons.hourglass_empty : Icons.help_outline),
            onPressed: _isProcessing ? null : () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('Tips'),
                    ],
                  ),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('For best results:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('✓ Use good lighting'),
                        Text('✓ Hold phone steady'),
                        Text('✓ Fill frame with price tag'),
                        Text('✓ Keep text straight'),
                        Text('✓ Tap to focus'),
                        SizedBox(height: 12),
                        Text('Avoid:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('✗ Blurry photos'),
                        Text('✗ Shadows or glare'),
                        Text('✗ Tilted angles'),
                        Text('✗ Low light'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Processing image...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Extracting text with AI',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Capture Price Tag',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Text(
                          'Take a photo of the price tag to automatically extract product name and price',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Tap ? for tips on best results',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.blue,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: _captureAndProcessImage,
                    icon: const Icon(Icons.camera),
                    label: const Text('Open Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _pickFromGallery(),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
