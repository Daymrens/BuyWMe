import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_item.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/autocomplete_provider.dart';
import '../theme/app_theme.dart';
import 'glassmorphic_card.dart';

/// Modern card-based Add Item bottom sheet
/// Replaces tab-based UI with expandable cards for better UX
class AddItemCardSheet extends ConsumerStatefulWidget {
  final String cartId;
  final Function(BuildContext, WidgetRef, String)? onScanBarcode;
  final Function(BuildContext, WidgetRef, String)? onScanReceipt;

  const AddItemCardSheet({
    required this.cartId,
    this.onScanBarcode,
    this.onScanReceipt,
    super.key,
  });

  @override
  ConsumerState<AddItemCardSheet> createState() => _AddItemCardSheetState();
}

class _AddItemCardSheetState extends ConsumerState<AddItemCardSheet>
    with SingleTickerProviderStateMixin {
  
  // Card expansion states
  bool _isQuickAddExpanded = false;
  bool _isManualEntryExpanded = false;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  
  // Form state
  String _selectedUnit = 'pcs';
  String? _selectedCategory;
  
  // Animation controller
  late AnimationController _animationController;
  
  // Autocomplete state
  late FocusNode _nameFocusNode;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    
    // Initialize focus node and listener for autocomplete
    _nameFocusNode = FocusNode();
    _nameController.addListener(_onNameChanged);
    _nameFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!_nameFocusNode.hasFocus) {
      setState(() => _showSuggestions = false);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _nameFocusNode.removeListener(_onFocusChanged);
    _nameFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_nameFocusNode.hasFocus && _nameController.text.isNotEmpty) {
      setState(() => _showSuggestions = true);
    } else {
      setState(() => _showSuggestions = false);
    }
  }

  void _selectSuggestion(String suggestion) {
    _nameController.text = suggestion;
    setState(() => _showSuggestions = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => GlassmorphicCard(
        borderRadius: 30,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ListView(
          controller: scrollController,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Quick Add Card
            _buildQuickAddCard()
                .animate()
                .fadeIn(delay: 100.ms)
                .slideY(begin: 0.1, end: 0, delay: 100.ms),
            
            const SizedBox(height: 16),
            
            // Smart Scanner Card
            _buildScannerCard()
                .animate()
                .fadeIn(delay: 150.ms)
                .slideY(begin: 0.1, end: 0, delay: 150.ms),
            
            const SizedBox(height: 16),
            
            // Manual Entry Card
            _buildManualEntryCard()
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.1, end: 0, delay: 200.ms),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_shopping_cart,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Item',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                'Choose how to add your item',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 1. Quick Add Card - Most common items with category filters
  Widget _buildQuickAddCard() {
    return _ExpandableActionCard(
      isExpanded: _isQuickAddExpanded,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isQuickAddExpanded = !_isQuickAddExpanded);
      },
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.primaryGreen.withOpacity(0.9),
          AppTheme.gradientEnd.withOpacity(0.95),
        ],
      ),
      icon: Icons.inventory_2,
      title: 'Quick Add',
      subtitle: 'Select from common items',
      collapsedPreview: _buildQuickItemsPreview(),
      expandedContent: _buildQuickAddExpanded(),
    );
  }

  Widget _buildQuickItemsPreview() {
    final quickItems = [
      {'emoji': '🥚', 'name': 'Eggs'},
      {'emoji': '🥛', 'name': 'Milk'},
      {'emoji': '🍞', 'name': 'Bread'},
    ];
    
    return Row(
      children: quickItems.map((item) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item['emoji']!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                item['name']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickAddExpanded() {
    final commonItems = _getCommonItems();
    final filteredItems = _selectedCategory != null
        ? commonItems.where((item) => item['category'] == _selectedCategory).toList()
        : commonItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        
        // Category filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('All', Icons.apps, Colors.grey, _selectedCategory == null, () {
                HapticFeedback.lightImpact();
                setState(() => _selectedCategory = null);
              }),
              _buildCategoryChip('Dairy', Icons.egg, Colors.orange, _selectedCategory == 'Dairy', () {
                HapticFeedback.lightImpact();
                setState(() => _selectedCategory = 'Dairy');
              }),
              _buildCategoryChip('Vegetables', Icons.eco, Colors.green, _selectedCategory == 'Vegetables', () {
                HapticFeedback.lightImpact();
                setState(() => _selectedCategory = 'Vegetables');
              }),
              _buildCategoryChip('Fruits', Icons.apple, Colors.red, _selectedCategory == 'Fruits', () {
                HapticFeedback.lightImpact();
                setState(() => _selectedCategory = 'Fruits');
              }),
              _buildCategoryChip('Meat', Icons.restaurant, Colors.brown, _selectedCategory == 'Meat', () {
                HapticFeedback.lightImpact();
                setState(() => _selectedCategory = 'Meat');
              }),
              _buildCategoryChip('Pantry', Icons.kitchen, Colors.purple, _selectedCategory == 'Pantry', () {
                HapticFeedback.lightImpact();
                setState(() => _selectedCategory = 'Pantry');
              }),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Grid of items
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filteredItems.map((item) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 80) / 2, // Half width minus padding
              child: _buildQuickItemTile(item),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickItemTile(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _addQuickItem(item);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkSurfaceVariant
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              item['icon'] as String,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₱${(item['price'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF00C853),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Smart Scanner Card - Camera and barcode options
  Widget _buildScannerCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B46C1), // Purple
            Color(0xFF4338CA), // Blue-purple
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // AI Badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Smart Scanner',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Scan price tag or barcode',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Scanner buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildScannerButton(
                        icon: Icons.camera_alt,
                        label: 'Receipt',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          widget.onScanReceipt?.call(context, ref, widget.cartId);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildScannerButton(
                        icon: Icons.qr_code,
                        label: 'Barcode',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          widget.onScanBarcode?.call(context, ref, widget.cartId);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Manual Entry Card - Custom item form
  Widget _buildManualEntryCard() {
    return _ExpandableActionCard(
      isExpanded: _isManualEntryExpanded,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isManualEntryExpanded = !_isManualEntryExpanded);
      },
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.orange.withOpacity(0.85),
          Colors.deepOrange.withOpacity(0.9),
        ],
      ),
      icon: Icons.edit,
      title: 'Manual Entry',
      subtitle: 'Type details yourself',
      collapsedPreview: const Row(
        children: [
          Icon(Icons.add, color: Colors.white, size: 20),
          SizedBox(width: 6),
          Text(
            'Create Custom Item',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      expandedContent: _buildManualEntryForm(),
    );
  }

  Widget _buildManualEntryForm() {
    return Column(
      children: [
        const SizedBox(height: 16),
        
        // Name field with autocomplete
        _buildNameFieldWithAutocomplete(),
        
        const SizedBox(height: 12),
        
        // Quantity and Unit
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'g', child: Text('g')),
                  DropdownMenuItem(value: 'L', child: Text('L')),
                  DropdownMenuItem(value: 'mL', child: Text('mL')),
                  DropdownMenuItem(value: 'pack', child: Text('pack')),
                  DropdownMenuItem(value: 'box', child: Text('box')),
                  DropdownMenuItem(value: 'dozen', child: Text('dozen')),
                ],
                onChanged: (value) {
                  setState(() => _selectedUnit = value!);
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Price field
        TextField(
          controller: _priceController,
          decoration: InputDecoration(
            labelText: 'Price (₱)',
            prefixText: '₱ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            filled: true,
          ),
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: 20),
        
        // Add button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addManualItem,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Add Item',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameFieldWithAutocomplete() {
    return Consumer(
      builder: (context, ref, child) {
        final suggestions = ref.watch(suggestionsProvider);
        
        return Stack(
          children: [
            // Name input field
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g., Custom Product',
                prefixIcon: const Icon(Icons.label),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
              ),
              onChanged: (value) {
                ref.read(suggestionsProvider.notifier).updateSuggestions(value);
              },
            ),
            
            // Suggestions dropdown
            if (_showSuggestions && suggestions.isNotEmpty)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        final frequency = ref
                            .read(suggestionsProvider.notifier)
                            .getFrequency(suggestion);
                        
                        return InkWell(
                          onTap: () => _selectSuggestion(suggestion),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: index < suggestions.length - 1
                                  ? Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.withOpacity(0.2),
                                        width: 0.5,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    suggestion,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (frequency > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '×$frequency',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : isDark 
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Data helpers
  List<Map<String, dynamic>> _getCommonItems() {
    return [
      {'name': 'Rice', 'unit': 'kg', 'price': 50.0, 'category': 'Grains', 'icon': '🌾'},
      {'name': 'Eggs', 'unit': 'dozen', 'price': 120.0, 'category': 'Dairy', 'icon': '🥚'},
      {'name': 'Milk', 'unit': 'L', 'price': 90.0, 'category': 'Dairy', 'icon': '🥛'},
      {'name': 'Bread', 'unit': 'pcs', 'price': 50.0, 'category': 'Bakery', 'icon': '🍞'},
      {'name': 'Chicken', 'unit': 'kg', 'price': 200.0, 'category': 'Meat', 'icon': '🍗'},
      {'name': 'Pork', 'unit': 'kg', 'price': 250.0, 'category': 'Meat', 'icon': '🥓'},
      {'name': 'Fish', 'unit': 'kg', 'price': 180.0, 'category': 'Seafood', 'icon': '🐟'},
      {'name': 'Tomatoes', 'unit': 'kg', 'price': 60.0, 'category': 'Vegetables', 'icon': '🍅'},
      {'name': 'Onions', 'unit': 'kg', 'price': 80.0, 'category': 'Vegetables', 'icon': '🧅'},
      {'name': 'Potatoes', 'unit': 'kg', 'price': 70.0, 'category': 'Vegetables', 'icon': '🥔'},
      {'name': 'Banana', 'unit': 'kg', 'price': 70.0, 'category': 'Fruits', 'icon': '🍌'},
      {'name': 'Apple', 'unit': 'kg', 'price': 150.0, 'category': 'Fruits', 'icon': '🍎'},
      {'name': 'Orange', 'unit': 'kg', 'price': 120.0, 'category': 'Fruits', 'icon': '🍊'},
      {'name': 'Cooking Oil', 'unit': 'L', 'price': 150.0, 'category': 'Pantry', 'icon': '🛢️'},
      {'name': 'Sugar', 'unit': 'kg', 'price': 80.0, 'category': 'Pantry', 'icon': '🍬'},
      {'name': 'Salt', 'unit': 'pack', 'price': 20.0, 'category': 'Pantry', 'icon': '🧂'},
    ];
  }

  void _addQuickItem(Map<String, dynamic> item) {
    final newItem = ShoppingItem(
      id: const Uuid().v4(),
      productId: const Uuid().v4(),
      name: item['name'] as String,
      quantity: 1,
      unit: item['unit'] as String,
      estimatedPrice: item['price'] as double,
    );
    
    ref.read(shoppingListProvider.notifier).addItem(widget.cartId, newItem);
    Navigator.pop(context);
    
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
    if (_nameController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final newItem = ShoppingItem(
      id: const Uuid().v4(),
      productId: const Uuid().v4(),
      name: _nameController.text,
      quantity: double.parse(_quantityController.text),
      unit: _selectedUnit,
      estimatedPrice: double.parse(_priceController.text),
    );
    
    ref.read(shoppingListProvider.notifier).addItem(widget.cartId, newItem);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_nameController.text} added!'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Reusable expandable card component
class _ExpandableActionCard extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget collapsedPreview;
  final Widget expandedContent;

  const _ExpandableActionCard({
    required this.isExpanded,
    required this.onTap,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.collapsedPreview,
    required this.expandedContent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                
                // Content
                AnimatedCrossFade(
                  firstChild: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: collapsedPreview,
                  ),
                  secondChild: expandedContent,
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
