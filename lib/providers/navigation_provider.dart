import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks active main shell page index (0: Dashboard, 6: Production Register, 9: Inventory Stock Ledger, etc.)
final shellNavigationIndexProvider = StateProvider<int>((ref) => 0);

/// Tracks target inventory item ID when deep-navigating to Stock Page / Ledger
final stockLedgerTargetItemProvider = StateProvider<String?>((ref) => null);

/// Tracks target month when deep-navigating to Stock Page / Ledger
final stockLedgerTargetMonthProvider = StateProvider<DateTime?>((ref) => null);
