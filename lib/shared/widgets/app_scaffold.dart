import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sidebar_nav.dart';
import '../../features/invoice/view/invoice_page.dart';
import '../../features/invoice_history/view/invoice_history_page.dart';
import '../../features/products/view/products_page.dart';
import '../../features/customers/view/customers_page.dart';
import '../../features/suppliers/view/suppliers_page.dart';
import '../../features/dashboard/view/dashboard_page.dart';
import '../../features/settings/view/settings_page.dart';
import '../../features/purchases/view/purchase_page.dart';
import '../../features/purchases/view/purchase_history_page.dart';

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
    setState(() => _currentPage = page);
  }

  /// Navigate to invoice editor with a specific invoice ID.
  Future<void> editInvoice(int invoiceId) async {
    if (onWillNavigateAway != null) {
      final canNavigate = await onWillNavigateAway!();
      if (!canNavigate) return;
    }
    setState(() {
      _currentPage = NavPage.newInvoice;
    });
    // We pass the invoice ID through a ValueKey so InvoicePage knows to load it
    _editInvoiceId = invoiceId;
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

  @override
  Widget build(BuildContext context) {
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
          child: Scaffold(
            body: Row(
              children: [
                // ── Sidebar ────────────────────────────────────
                SidebarNav(
                  currentPage: _currentPage,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                      _editInvoiceId = null;
                      _filterPurchaseProductId = null;
                      _filterPurchaseSupplierId = null;
                    });
                  },
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
        return InvoicePage(
          key: ValueKey('invoice_$id'),
          editInvoiceId: id,
          onSavedAndGoBack: id != null
              ? () => setState(() => _currentPage = NavPage.invoiceHistory)
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
          onViewProductPurchases: (productId) {
            setState(() {
              _currentPage = NavPage.purchaseHistory;
              _filterPurchaseProductId = productId;
            });
          },
        );
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
