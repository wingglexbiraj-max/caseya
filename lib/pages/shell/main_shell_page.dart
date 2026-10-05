import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_sidebar.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../dashboard/dashboard_page.dart';
import '../lab/lab_page.dart';
import '../product_calculator/product_calculator_page.dart';
import '../milk_standardization/milk_standardization_page.dart';
import '../boiler/boiler_page.dart';
import '../dg_hsd/dg_hsd_page.dart';
import '../production/production_page.dart';
import '../batch_records/batch_records_page.dart';
import '../dispatch/dispatch_page.dart';
import '../stock/stock_page.dart';
import '../reports/reports_page.dart';
import '../products_master/products_master_page.dart';
import '../settings/settings_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<String> _pageTitles = [
    'Dashboard',
    'Lab Fat & SNF',
    'Product Calculator',
    'Milk Standardization',
    'Boiler Fuel Consumption',
    'DG HSD Fuel & Energy',
    'Production Register',
    'Daily Batch Making Records',
    'Dispatch Records',
    'Inventory Stocks',
    'Reports & Export',
    'Products & Standards Master',
    'Settings & Permissions',
  ];

  static const List<String> _pageSubtitles = [
    'Plant Operational Metrics & Production KPIs Overview',
    'Record & analyze daily milk silo fat, SNF, and laboratory quality tests',
    'Instant plant conversions: Total Pieces, Packing Needed, Total Quantity, and Commercial Price',
    'Batch formulation engine: Calculate required SMP, Sugar, and Water from available milk FAT and SNF',
    'Shift fuel level monitoring using plant formula: ((Opening CM - Closing CM) × 900) ÷ 70',
    'Diesel Generator shift fuel consumption, power generation (kWh), and efficiency monitoring',
    'Daily pasteurization and packaging floor output batches',
    'Record, track, and aggregate recipe formulations and raw material consumption date-wise',
    'Finished goods transport distribution with dynamic multi-product consolidation',
    'Finished goods inventory, raw materials, packaging supplies, and cold room holdings',
    'Operational reports, shift filters, and clean CSV/Excel spreadsheet exports',
    'Plant product catalog, pack sizes, crate capacities, target fat & SNF standards',
    'Configure plant operational formulas, user permissions, and API backend connections',
  ];

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _openMoreMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'More Plant Modules',
                  style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.body),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.electric_bolt_outlined, color: AppColors.primary),
                title: const Text('DG HSD Fuel'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onNavigate(5);
                },
              ),
              ListTile(
                leading: const Icon(Icons.factory_outlined, color: AppColors.primary),
                title: const Text('Production Register'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onNavigate(6);
                },
              ),
              ListTile(
                leading: const Icon(Icons.blender_outlined, color: AppColors.primary),
                title: const Text('Daily Batch Making'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onNavigate(7);
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                title: const Text('Dispatch Records'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onNavigate(8);
                },
              ),
              ListTile(
                leading: const Icon(Icons.warehouse_outlined, color: AppColors.primary),
                title: const Text('Inventory Stocks'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onNavigate(9);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_outlined, color: AppColors.primary),
                title: const Text('Reports & Export'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onNavigate(10);
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_list_bulleted, color: AppColors.primary),
                title: const Text('Products Master'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onNavigate(11);
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune_outlined, color: AppColors.primary),
                title: const Text('Settings & Roles'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onNavigate(12);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    final Widget bodyWidget = IndexedStack(
      index: _selectedIndex,
      children: [
        SelectionArea(child: DashboardPage(onNavigate: _onNavigate)),
        const SelectionArea(child: LabPage()),
        const SelectionArea(child: ProductCalculatorPage()),
        const SelectionArea(child: MilkStandardizationPage()),
        const SelectionArea(child: BoilerPage()),
        const SelectionArea(child: DgHsdPage()),
        const SelectionArea(child: ProductionPage()),
        const SelectionArea(child: BatchRecordsPage()),
        const SelectionArea(child: DispatchPage()),
        const SelectionArea(child: StockPage()),
        const SelectionArea(child: ReportsPage()),
        const SelectionArea(child: ProductsMasterPage()),
        const SelectionArea(child: SettingsPage()),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: isMobile
          ? Drawer(
              child: AppSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: _onNavigate,
              ),
            )
          : null,
      bottomNavigationBar: isMobile
          ? AppBottomNav(
              selectedIndex: _selectedIndex,
              onItemSelected: _onNavigate,
              onMorePressed: _openMoreMenu,
            )
          : null,
      body: Row(
        children: [
          // Desktop Persistent Sidebar
          if (!isMobile)
            AppSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onNavigate,
            ),

          // Main View Content with AppHeader
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  activeTitle: _pageTitles[_selectedIndex],
                  activeSubtitle: _pageSubtitles[_selectedIndex],
                  onMenuPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                Expanded(child: bodyWidget),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
