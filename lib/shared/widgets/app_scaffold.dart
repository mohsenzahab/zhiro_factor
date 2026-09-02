import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sidebar_nav.dart';
import '../../features/invoice/view/invoice_page.dart';
import '../../features/invoice_history/view/invoice_history_page.dart';
import '../../features/products/view/products_page.dart';
import '../../features/customers/view/customers_page.dart';
import '../../features/dashboard/view/dashboard_page.dart';

/// Main application shell with sidebar and page switching.
class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => AppScaffoldState();
}

class AppScaffoldState extends State<AppScaffold> {
  NavPage _currentPage = NavPage.newInvoice;

  /// Navigate to a specific page (can be called externally via GlobalKey).
  void navigateTo(NavPage page) {
    setState(() => _currentPage = page);
  }

  /// Navigate to invoice editor with a specific invoice ID.
  void editInvoice(int invoiceId) {
    setState(() {
      _currentPage = NavPage.newInvoice;
    });
    // We pass the invoice ID through a ValueKey so InvoicePage knows to load it
    _editInvoiceId = invoiceId;
  }

  int? _editInvoiceId;

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
      case NavPage.products:
        return const ProductsPage();
      case NavPage.customers:
        return CustomersPage(
          onViewCustomerInvoices: (customerId) {
            setState(() => _currentPage = NavPage.invoiceHistory);
          },
        );
      case NavPage.dashboard:
        return const DashboardPage();
    }
  }
}
