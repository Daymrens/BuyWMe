import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_item.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/favorite_provider.dart';
import '../theme/app_theme.dart';

/// Simple, user-friendly Add Item bottom sheet
/// Clean design with easy navigation and quick actions
class SimpleAddItemSheet extends ConsumerStatefulWidget {
  final String cartId;
  final Function(BuildContext, WidgetRef, String)? onScanBarcode;
  final Function(BuildContext, WidgetRef, String)? onScanReceipt;

  const SimpleAddItemSheet({
    required this.cartId,
    this.onScanBarcode,
    this.onScanReceipt,
    super.key,
  });

  @override
  ConsumerState<SimpleAddItemSheet> createState() => _SimpleAddItemSheetState();
}

class _SimpleAddItemSheetState extends ConsumerState<SimpleAddItemSheet> {
  // Current view: 'main', 'quick', 'manual'
  String _currentView = 'main';
  
  // Form controllers
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  String _selectedUnit = 'pcs';
  bool _addToFavorites = false;

  // Common items for quick add
  final Map<String, List<Map<String, dynamic>>> _commonItems = {
    'All': [
      {'name': 'Rice', 'icon': '🍚', 'price': 50.0, 'unit': 'kg'},
      {'name': 'Eggs', 'icon': '🥚', 'price': 8.0, 'unit': 'pcs'},
      {'name': 'Bread', 'icon': '🍞', 'price': 45.0, 'unit': 'pack'},
      {'name': 'Milk', 'icon': '🥛', 'price': 85.0, 'unit': 'L'},
      {'name': 'Chicken', 'icon': '🍗', 'price': 180.0, 'unit': 'kg'},
      {'name': 'Fish', 'icon': '🐟', 'price': 200.0, 'unit': 'kg'},
    ],
    'Vegetables': [
      {'name': 'Tomato', 'icon': '🍅', 'price': 60.0, 'unit': 'kg'},
      {'name': 'Onion', 'icon': '🧅', 'price': 80.0, 'unit': 'kg'},
      {'name': 'Potato', 'icon': '🥔', 'price': 50.0, 'unit': 'kg'},
      {'name': 'Carrot', 'icon': '🥕', 'price': 70.0, 'unit': 'kg'},
    ],
    'Fruits': [
      {'name': 'Apple', 'icon': '🍎', 'price': 120.0, 'unit': 'kg'},
      {'name': 'Banana', 'icon': '🍌', 'price': 60.0, 'unit': 'kg'},
      {'name': 'Orange', 'icon': '🍊', 'price': 100.0, 'unit': 'kg'},
      {'name': 'Grapes', 'icon': '🍇', 'price': 150.0, 'unit': 'kg'},
    ],
  };

  String _selectedCategory = 'All';

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF0A0E21), const Color(0xFF1D1F33)]
              : [const Color(0xFFF5F7FA), const Color(0xFFE8EAF6)],
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Content
                Expanded(
                  child: _currentView == 'main'
                      ? _buildMainView(scrollController)
                      : _currentView == 'quick'
                          ? _buildQuickAddView(scrollController)
                          : _buildManualView(scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title with back button
          Row(
            children: [
              if (_currentView != 'main')
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() => _currentView = 'main');
                  },
                ),
              if (_currentView == 'main') const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentView == 'main'
                          ? 'Add Item'
                          : _currentView == 'quick'
                              ? 'Quick Add'
                              : 'Manual Entry',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      _currentView == 'main'
                          ? 'Choose how to add'
                          : _currentView == 'quick'
                              ? 'Select from common items'
                              : 'Enter item details',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentView != 'main')
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainView(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Quick Add Option
        _buildMainOption(
          icon: Icons.flash_on,
          title: 'Quick Add',
          subtitle: 'Choose from common items',
          gradient: LinearGradient(
            colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.7)],
          ),
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() => _currentView = 'quick');
          },
        ).animate().fadeIn(delay: 50.ms).slideX(begin: -0.2),
        
        const SizedBox(height: 16),
        
        // Scan Barcode Option
        _buildMainOption(
          icon: Icons.qr_code_scanner,
          title: 'Scan Barcode',
          subtitle: 'Find product by barcode',
          gradient: const LinearGradient(
            colors: [Colors.blue, Color(0xFF5C6BC0)],
          ),
          onTap: () {
            HapticFeedback.mediumImpact();
            final callback = widget.onScanBarcode;
            final cartId = widget.cartId;
            Navigator.pop(context);
            if (callback != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                callback(context, ref, cartId);
              });
            }
          },
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
        
        const SizedBox(height: 16),
        
        // Scan Receipt Option
        _buildMainOption(
          icon: Icons.camera_alt,
          title: 'Scan Receipt',
          subtitle: 'Extract items from photo',
          gradient: const LinearGradient(
            colors: [Colors.purple, Color(0xFF9C27B0)],
          ),
          onTap: () {
            HapticFeedback.mediumImpact();
            final callback = widget.onScanReceipt;
            final cartId = widget.cartId;
            Navigator.pop(context);
            if (callback != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                callback(context, ref, cartId);
              });
            }
          },
        ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.2),
        
        const SizedBox(height: 16),
        
        // Manual Entry Option
        _buildMainOption(
          icon: Icons.edit,
          title: 'Manual Entry',
          subtitle: 'Type item details yourself',
          gradient: const LinearGradient(
            colors: [Colors.orange, Color(0xFFFF9800)],
          ),
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() => _currentView = 'manual');
          },
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
      ],
    );
  }

  Widget _buildMainOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddView(ScrollController scrollController) {
    final items = _commonItems[_selectedCategory] ?? [];
    
    return Column(
      children: [
        // Category filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _commonItems.keys.map((category) {
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedCategory = category);
                  },
                  selectedColor: AppTheme.primaryGreen,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Items grid
        Expanded(
          child: GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildQuickAddItem(
                icon: item['icon'],
                name: item['name'],
                price: item['price'],
                unit: item['unit'],
                onTap: () {
                  _addQuickItem(item);
                },
              ).animate(delay: Duration(milliseconds: index * 50))
                  .fadeIn()
                  .scale(begin: const Offset(0.8, 0.8));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddItem({
    required String icon,
    required String name,
    required double price,
    required String unit,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '₱${price.toStringAsFixed(0)}/$unit',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualView(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Product Name
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Product Name',
            hintText: 'e.g., Rice, Milk, Eggs',
            prefixIcon: const Icon(Icons.shopping_basket),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.1),
          ),
        ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
        
        const SizedBox(height: 16),
        
        // Quantity and Unit Row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.1),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: InputDecoration(
                  labelText: 'Unit',
                  prefixIcon: const Icon(Icons.straighten),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.1),
                ),
                items: const [
                  DropdownMenuItem(value: 'pcs', child: Text('Pieces')),
                  DropdownMenuItem(value: 'kg', child: Text('Kilogram')),
                  DropdownMenuItem(value: 'g', child: Text('Grams')),
                  DropdownMenuItem(value: 'L', child: Text('Liter')),
                  DropdownMenuItem(value: 'mL', child: Text('Milliliter')),
                  DropdownMenuItem(value: 'pack', child: Text('Pack')),
                ],
                onChanged: (value) {
                  setState(() => _selectedUnit = value!);
                },
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Price
        TextField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Price (Optional)',
            hintText: 'Estimated price',
            prefixIcon: const Icon(Icons.attach_money),
            prefixText: '₱ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.1),
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
        
        const SizedBox(height: 16),
        
        // Add to Favorites checkbox
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _addToFavorites ? AppTheme.primaryGreen : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: CheckboxListTile(
            value: _addToFavorites,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() => _addToFavorites = value ?? false);
            },
            title: const Text('Add to Favorites'),
            subtitle: const Text('Quick access for future purchases'),
            secondary: Icon(
              _addToFavorites ? Icons.star : Icons.star_outline,
              color: _addToFavorites ? Colors.amber : Colors.grey,
              size: 24,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
        
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _addManualItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_circle),
              SizedBox(width: 8),
              Text(
                'Add to Cart',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
      ],
    );
  }

  void _addQuickItem(Map<String, dynamic> item) {
    final newItem = ShoppingItem(
      id: const Uuid().v4(),
      productId: const Uuid().v4(),
      name: item['name'],
      quantity: 1,
      unit: item['unit'],
      estimatedPrice: item['price'].toDouble(),
    );
    
    ref.read(shoppingListProvider.notifier).addItem(widget.cartId, newItem);
    
    // Optionally add to favorites (pre-add for frequently used items)
    ref.read(favoriteProvider.notifier).addFavorite(
      itemName: item['name'],
      price: item['price'].toDouble(),
    );
    
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${item['name']} added!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(overlayEntry);
    
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _addManualItem() {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a product name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    
    final newItem = ShoppingItem(
      id: const Uuid().v4(),
      productId: const Uuid().v4(),
      name: name,
      quantity: quantity,
      unit: _selectedUnit,
      estimatedPrice: price,
    );
    
    ref.read(shoppingListProvider.notifier).addItem(widget.cartId, newItem);
    
    // Add to favorites if requested
    if (_addToFavorites) {
      ref.read(favoriteProvider.notifier).addFavorite(
        itemName: name,
        price: price > 0 ? price : null,
      );
    }
    
    // Reset favorite toggle for next item
    setState(() => _addToFavorites = false);
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added to cart!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}
