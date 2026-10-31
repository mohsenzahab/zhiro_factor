import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/responsive/responsive_breakpoints.dart';
import 'sidebar_nav.dart';
import '../../features/invoice/view/invoice_page.dart';
import '../../features/invoice_history/view/invoice_history_page.dart';
import '../../features/products/view/products_page.dart';
import '../../features/products/view/product_sales_history_page.dart';
import '../../features/customers/view/customers_page.dart';
import '../../features/suppliers/view/suppliers_page.dart';
import '../../features/dashboard/view/dashboard_page.dart';
import '../../features/settings/view/settings_page.dart';
import '../../features/purchases/view/purchase_page.dart';
import '../../features/purchases/view/purchase_history_page.dart';
import '../../features/demands/view/demands_page.dart';

/// Main application shell with sidebar and page switching.
class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => AppScaffoldState();
}

class AppScaffoldState extends State<AppScaffold> {
  NavPage _currentPage = NavPage.newInvoice;

  /// Global interceptor for navigation (used to show discard warnings).
  static Future<bool> Function()? onWillNavigateAway;

  /// Navigate to a specific page (can be called externally via GlobalKey).
  Future<void> navigateTo(NavPage page) async {
    if (page == _currentPage) return;
    if (onWillNavigateAway != null) {
      final canNavigate = await onWillNavigateAway!();
      if (!canNavigate) return;
    }
    setState(() {
      _currentPage = page;
      _editInvoiceId = null;
      _filterPurchaseProductId = null;
      _filterPurchaseSupplierId = null;
      if (page != NavPage.productSalesHistory) {
        _salesHistoryProductId = null;
      }
      _returnPageAfterInvoice = null;
    });
  }

  /// Navigate to invoice editor with a specific invoice ID.
  Future<void> editInvoice(int invoiceId, {NavPage? returnPage}) async {
    if (onWillNavigateAway != null) {
      final canNavigate = await onWillNavigateAway!();
      if (!canNavigate) return;
    }
    setState(() {
      _currentPage = NavPage.newInvoice;
      _editInvoiceId = invoiceId;
      _returnPageAfterInvoice = returnPage;
    });
  }

  /// Navigate to purchase editor with a specific purchase ID.
  Future<void> editPurchase(int purchaseId) async {
    if (onWillNavigateAway != null) {
      final canNavigate = await onWillNavigateAway!();
      if (!canNavigate) return;
    }
    setState(() {
      _currentPage = NavPage.newPurchase;
    });
    _editPurchaseId = purchaseId;
  }

  int? _editInvoiceId;
  int? _editPurchaseId;
  int? _filterPurchaseProductId;
  int? _filterPurchaseSupplierId;
  int? _salesHistoryProductId;
  NavPage? _returnPageAfterInvoice;

  String _getPageTitle(NavPage page) {
    switch (page) {
      case NavPage.newInvoice:
        return _editInvoiceId != null ? AppStrings.editInvoice : AppStrings.navNewInvoice;
      case NavPage.invoiceHistory:
        return AppStrings.navInvoiceHistory;
      case NavPage.newPurchase:
        return AppStrings.newPurchase;
      case NavPage.purchaseHistory:
        return AppStrings.purchaseHistory;
      case NavPage.products:
        return AppStrings.navProducts;
      case NavPage.productSalesHistory:
        return AppStrings.productSalesHistory;
      case NavPage.demands:
        return AppStrings.navDemands;
      case NavPage.customers:
        return AppStrings.navCustomers;
      case NavPage.suppliers:
        return AppStrings.navSuppliers;
      case NavPage.dashboard:
        return AppStrings.navDashboard;
      case NavPage.settings:
        return AppStrings.navSettings;
    }
  }

  int _getBottomNavIndex(NavPage page) {
    switch (page) {
      case NavPage.newInvoice:
        return 0;
      case NavPage.invoiceHistory:
        return 1;
      case NavPage.products:
      case NavPage.productSalesHistory:
        return 2;
      case NavPage.dashboard:
        return 3;
      default:
        return 4; // Other pages (Purchases, Demands, Customers, Suppliers, Settings)
    }
  }

  void _onBottomNavTapped(int index, BuildContext scaffoldCtx) {
    switch (index) {
      case 0:
        navigateTo(NavPage.newInvoice);
        break;
      case 1:
        navigateTo(NavPage.invoiceHistory);
        break;
      case 2:
        navigateTo(NavPage.products);
        break;
      case 3:
        navigateTo(NavPage.dashboard);
        break;
      case 4:
        Scaffold.of(scaffoldCtx).openDrawer();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          navigateTo(NavPage.newInvoice);
        },
      },
      child: Focus(
        autofocus: true,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: isMobile
              ? Scaffold(
                  appBar: AppBar(
                    title: Text(
                      _getPageTitle(_currentPage),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    backgroundColor: AppColors.scaffoldDark,
                    elevation: 0,
                    leading: Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu),
                        tooltip: 'منوی برنامه',
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                  ),
                  drawer: Drawer(
                    backgroundColor: AppColors.surfaceDark,
                    child: SafeArea(
                      child: SidebarNav(
                        isDrawer: true,
                        currentPage: _currentPage,
                        onPageChanged: (page) => navigateTo(page),
                      ),
                    ),
                  ),
                  body: _buildPage(),
                  bottomNavigationBar: Builder(
                    builder: (scaffoldCtx) => BottomNavigationBar(
                      currentIndex: _getBottomNavIndex(_currentPage),
                      onTap: (idx) => _onBottomNavTapped(idx, scaffoldCtx),
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: AppColors.cardDark,
                      selectedItemColor: AppColors.primary,
                      unselectedItemColor: AppColors.textMuted,
                      selectedFontSize: 11,
                      unselectedFontSize: 11,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.receipt_long_outlined),
                          activeIcon: Icon(Icons.receipt_long),
                          label: 'فاکتور',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.history_outlined),
                          activeIcon: Icon(Icons.history),
                          label: 'تاریخچه',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.inventory_2_outlined),
                          activeIcon: Icon(Icons.inventory_2),
                          label: 'کالاها',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.dashboard_outlined),
                          activeIcon: Icon(Icons.dashboard),
                          label: 'داشبورد',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.grid_view_rounded),
                          activeIcon: Icon(Icons.grid_view_rounded),
                          label: 'سایر بخش‌ها',
                        ),
                      ],
                    ),
                  ),
                )
              : Scaffold(
                  body: Row(
                    children: [
                      // ── Sidebar ────────────────────────────────────
                      SidebarNav(
                        currentPage: _currentPage,
                        onPageChanged: (page) => navigateTo(page),
                      ),

                      // ── Main Content ───────────────────────────────
                      Expanded(
                        child: _buildPage(),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (_currentPage) {
      case NavPage.newInvoice:
        final id = _editInvoiceId;
        _editInvoiceId = null; // Consume the ID
        final returnPage = _returnPageAfterInvoice;
        _returnPageAfterInvoice = null;
        return InvoicePage(
          key: ValueKey('invoice_$id'),
          editInvoiceId: id,
          onSavedAndGoBack: id != null
              ? () => setState(() => _currentPage = returnPage ?? NavPage.invoiceHistory)
              : null,
        );
      case NavPage.invoiceHistory:
        return InvoiceHistoryPage(
          onEditInvoice: (id) => editInvoice(id),
        );
      case NavPage.newPurchase:
        final pid = _editPurchaseId;
        _editPurchaseId = null;
        return PurchasePage(
          key: ValueKey('purchase_$pid'),
          editPurchaseId: pid,
          onSavedAndGoBack: pid != null
              ? () => setState(() => _currentPage = NavPage.purchaseHistory)
              : null,
        );
      case NavPage.purchaseHistory:
        final fProdId = _filterPurchaseProductId;
        final fSuppId = _filterPurchaseSupplierId;
        _filterPurchaseProductId = null;
        _filterPurchaseSupplierId = null;
        return PurchaseHistoryPage(
          onEditPurchase: (id) => editPurchase(id),
          productId: fProdId,
          supplierId: fSuppId,
        );
      case NavPage.products:
        return ProductsPage(
          onViewProductSales: (productId) {
            setState(() {
              _currentPage = NavPage.productSalesHistory;
              _salesHistoryProductId = productId;
            });
          },
          onViewProductPurchases: (productId) {
            setState(() {
              _currentPage = NavPage.purchaseHistory;
              _filterPurchaseProductId = productId;
            });
          },
        );
      case NavPage.productSalesHistory:
        final pid = _salesHistoryProductId;
        return ProductSalesHistoryPage(
          productId: pid,
          onBack: () {
            setState(() {
              _currentPage = NavPage.products;
              _salesHistoryProductId = null;
            });
          },
          onViewInvoice: (invoiceId) => editInvoice(
            invoiceId,
            returnPage: NavPage.productSalesHistory,
          ),
        );
      case NavPage.demands:
        return const DemandsPage();
      case NavPage.customers:
        return CustomersPage(
          onViewCustomerInvoices: (customerId) {
            setState(() => _currentPage = NavPage.invoiceHistory);
          },
        );
      case NavPage.suppliers:
        return SuppliersPage(
          onViewSupplierPurchases: (supplierId) {
            setState(() {
              _currentPage = NavPage.purchaseHistory;
              _filterPurchaseSupplierId = supplierId;
            });
          },
        );
      case NavPage.dashboard:
        return const DashboardPage();
      case NavPage.settings:
        return SettingsPage(
          onSettingsSaved: () => setState(() {}),
        );
    }
  }
}
