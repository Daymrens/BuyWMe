Design the app to feel like a premium 2026 consumer app (think Notion, Grab, or
a modern fintech app). Do NOT use default Material Design out-of-the-box look.

### Visual Style
- Dark mode first, with a light mode toggle
- Glassmorphism cards: frosted glass effect using BackdropFilter + blur on
  key cards (cart summary, store cards, price chart container)
- Soft gradient backgrounds — avoid flat solid colors for screens
- Rounded corners everywhere: BorderRadius.circular(20) minimum
- Subtle drop shadows with low opacity (not hard shadows)
- Primary accent: a custom green (#00C853) with a gradient variant
  (#00C853 → #1DE9B6) — used on CTAs, FABs, and highlights

### Typography
- Use Google Fonts: Poppins for headings, Inter for body text
- Font weights: 700 for titles, 500 for labels, 400 for body
- Avoid default Roboto everywhere

### Animations & Micro-interactions
- Hero transitions between list screen → list detail
- Staggered list item animations on screen load (slide up + fade in)
- Animated checkmark when item is marked done
- Smooth bottom sheet transitions for add/edit forms (DraggableScrollableSheet)
- Lottie animation for empty states (use lottie package)
- Haptic feedback on key actions (item check, scan success)

### Layout Patterns
- Bottom nav bar with floating style (rounded, slight elevation, blurred bg)
- Home screen: dashboard-style with summary cards in a horizontal scroll row
- Product/item cards: image placeholder icon on left, info on right — NOT
  just plain list tiles
- Use SliverAppBar with collapsing header on detail screens
- FAB (Floating Action Button) with extended label on main screens

### Components
- Custom SnackBar (bottom toast style, rounded, colored by action type)
- Skeleton loading shimmer on any list that loads from Hive (use shimmer package)
- Bottom sheets instead of full-page dialogs for quick add forms
- Pill-shaped filter chips for categories (e.g., Dairy, Produce, Frozen)

### Dependencies to add
  google_fonts: ^6.2.1
  lottie: ^3.1.2
  shimmer: ^3.0.0
  flutter_animate: ^4.5.0   # for staggered animations