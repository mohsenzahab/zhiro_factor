import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// Navigation page enum.
enum NavPage {
  newInvoice,
  invoiceHistory,
  products,
  customers,
  dashboard,
}

/// Sidebar navigation item data.
class _NavItem {
  final NavPage page;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.page,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const _navItems = <_NavItem>[
  _NavItem(
    page: NavPage.newInvoice,
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
    label: AppStrings.navNewInvoice,
  ),
  _NavItem(
    page: NavPage.invoiceHistory,
    icon: Icons.history_outlined,
    activeIcon: Icons.history,
    label: AppStrings.navInvoiceHistory,
  ),
  _NavItem(
    page: NavPage.products,
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
    label: AppStrings.navProducts,
  ),
  _NavItem(
    page: NavPage.customers,
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    label: AppStrings.navCustomers,
  ),
  _NavItem(
    page: NavPage.dashboard,
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: AppStrings.navDashboard,
  ),
];

/// Collapsible RTL sidebar navigation.
class SidebarNav extends StatefulWidget {
  final NavPage currentPage;
  final ValueChanged<NavPage> onPageChanged;

  const SidebarNav({
    super.key,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  State<SidebarNav> createState() => _SidebarNavState();
}

class _SidebarNavState extends State<SidebarNav> with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final AnimationController _animController;
  late final Animation<double> _widthAnim;

  static const double _expandedWidth = 220;
  static const double _collapsedWidth = 68;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _widthAnim = Tween<double>(begin: _expandedWidth, end: _collapsedWidth).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animController.reverse();
      } else {
        _animController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnim,
      builder: (context, child) {
        return Container(
          width: _widthAnim.value,
          decoration: BoxDecoration(
            gradient: AppColors.sidebarGradient,
            border: Border(
              left: BorderSide(color: AppColors.dividerDark, width: 1),
            ),
          ),
          child: Column(
            children: [
              // ── Brand Header ──────────────────────────────────
              _buildHeader(),
              const SizedBox(height: 8),
              Divider(color: AppColors.dividerDark, height: 1),
              const SizedBox(height: 8),

              // ── Nav Items ─────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _navItems.length,
                  itemBuilder: (context, index) {
                    return _buildNavItem(_navItems[index]);
                  },
                ),
              ),

              // ── Collapse Toggle ───────────────────────────────
              Divider(color: AppColors.dividerDark, height: 1),
              _buildCollapseButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt, color: Colors.white, size: 20),
          ),
          if (_expanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.appTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.appSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(_NavItem item) {
    final isActive = widget.currentPage == item.page;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onPageChanged(item.page),
          hoverColor: AppColors.sidebarHover,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: _expanded ? 12 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isActive ? AppColors.sidebarActiveItem.withValues(alpha: 0.15) : null,
              border: isActive
                  ? Border.all(color: AppColors.sidebarActiveItem.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: _expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 22,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                if (_expanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isActive ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return InkWell(
      onTap: _toggle,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        child: AnimatedRotation(
          turns: _expanded ? 0 : 0.5,
          duration: const Duration(milliseconds: 250),
          child: const Icon(
            Icons.chevron_right,
            color: AppColors.textMuted,
            size: 22,
          ),
        ),
      ),
    );
  }
}
