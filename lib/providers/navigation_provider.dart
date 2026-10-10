import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks active main shell page index (0: Dashboard, 6: Production Register, 9: Inventory Stock Ledger, etc.)
final shellNavigationIndexProvider = StateProvider<int>((ref) => 0);

/// Tracks target inventory item ID when deep-navigating to Stock Page / Ledger
final stockLedgerTargetItemProvider = StateProvider<String?>((ref) => null);

/// Tracks target month when deep-navigating to Stock Page / Ledger
final stockLedgerTargetMonthProvider = StateProvider<DateTime?>((ref) => null);

/// Tracks specific date to highlight in the stock ledger
final stockLedgerHighlightDateProvider = StateProvider<DateTime?>((ref) => null);

/// Tracks target report section in Reports Catalogue ('stock', 'boiler', 'dg', 'batch', 'production', 'dispatch')
final targetReportSectionProvider = StateProvider<String?>((ref) => null);

/// Represents the consumption and packaging details right after recording a production entry
class ProductionConsumptionEvent {
  final String recordId;
  final String batchNo;
  final String productId;
  final String productName;
  final double quantityProduced;
  final String unit;
  final int pieces;
  final double crates;
  final String date;
  final String time;
  final bool isBackDate;
  final List<dynamic> consumedPackaging;

  const ProductionConsumptionEvent({
    required this.recordId,
    required this.batchNo,
    required this.productId,
    required this.productName,
    required this.quantityProduced,
    required this.unit,
    required this.pieces,
    required this.crates,
    required this.date,
    required this.time,
    required this.isBackDate,
    required this.consumedPackaging,
  });
}

/// Holds the latest recorded production consumption event for immediate UI feedback & deep-linking
final latestProductionConsumptionProvider = StateProvider<ProductionConsumptionEvent?>((ref) => null);
