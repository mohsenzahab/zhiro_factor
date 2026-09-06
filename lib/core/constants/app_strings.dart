/// All user-facing Persian string constants for ZhiroFactor.
class AppStrings {
  AppStrings._();

  // ─── App ────────────────────────────────────────────────────────────
  static const String appTitle = 'ژیروفاکتور';
  static const String appSubtitle = 'مدیریت فروش و فاکتور';

  // ─── Navigation ─────────────────────────────────────────────────────
  static const String navNewInvoice = 'فاکتور جدید';
  static const String navInvoiceHistory = 'تاریخچه فاکتورها';
  static const String navProducts = 'مدیریت کالاها';
  static const String navCustomers = 'مشتریان';
  static const String navDashboard = 'گزارشات و داشبورد';

  // ─── Product ────────────────────────────────────────────────────────
  static const String products = 'کالاها';
  static const String productCode = 'کد کالا';
  static const String productName = 'نام کالا';
  static const String productCategory = 'دسته‌بندی';
  static const String all = 'همه';
  static const String allCategories = 'همه دسته‌ها';
  static const String uncategorized = 'بدون دسته‌بندی';
  static const String productBuyPrice = 'قیمت خرید اولیه';
  static const String productCurrentBuyPrice = 'قیمت خرید روز';
  static const String productSellPrice = 'قیمت فروش';
  static const String productUnit = 'واحد';
  static const String productStock = 'موجودی';
  static const String infinite = 'نامحدود';
  static const String infiniteStock = 'موجودی نامحدود';
  static const String productBuyDate = 'تاریخ خرید';
  static const String productSupplier = 'تامین‌کننده';
  static const String addProduct = 'افزودن کالا';
  static const String editProduct = 'ویرایش کالا';
  static const String deleteProduct = 'حذف کالا';
  static const String searchProduct = 'جستجوی کالا...';
  static const String profitMargin = 'درصد سود';
  static const String profitAmount = 'میزان سود';
  static const String profit = 'سود';
  static const String soldCount = 'فروش رفته';
  static const String applyProfitMargin = 'اعمال درصد سود';
  static const String profitMarginHint = 'درصد سود نسبت به قیمت خرید';
  static const String profitMarginApplied = 'درصد سود روی همه کالاها اعمال شد';
  static const String batchActions = 'عملیات گروهی';
  static const String selectedCount = 'کالا انتخاب شده';
  static const String deleteSelected = 'حذف انتخاب‌شده‌ها';
  static const String moveToCategory = 'انتقال به دسته‌بندی';
  static const String clearSelection = 'لغو انتخاب';
  static const String selectAll = 'انتخاب همه';
  static const String deselectAll = 'لغو انتخاب همه';
  static const String selectDestinationCategory = 'انتخاب دسته‌بندی مقصد';
  static const String enterNewCategory = 'یا نام دسته‌بندی جدید را وارد کنید...';
  static const String categoryMovedSuccess = 'دسته‌بندی کالاهای انتخاب‌شده تغییر کرد';
  static const String batchDeleteSuccess = 'کالاهای انتخاب‌شده حذف شدند';
  static const String confirmBatchDelete = 'آیا از حذف {count} کالای انتخاب‌شده اطمینان دارید؟';

  // ─── Customer ───────────────────────────────────────────────────────
  static const String customers = 'مشتریان';
  static const String customerCode = 'کد مشتری';
  static const String customerName = 'نام مشتری';
  static const String customerPhone = 'تلفن';
  static const String customerAddress = 'آدرس';
  static const String customerNotes = 'یادداشت';
  static const String addCustomer = 'افزودن مشتری';
  static const String editCustomer = 'ویرایش مشتری';
  static const String deleteCustomer = 'حذف مشتری';
  static const String searchCustomer = 'جستجوی مشتری...';
  static const String viewInvoices = 'مشاهده فاکتورها';

  // ─── Invoice ────────────────────────────────────────────────────────
  static const String invoice = 'فاکتور';
  static const String invoiceNumber = 'شماره فاکتور';
  static const String invoiceDate = 'تاریخ';
  static const String invoiceStatus = 'وضعیت';
  static const String selectCustomer = 'انتخاب مشتری';
  static const String addItem = 'افزودن کالا';
  static const String rowNumber = 'ردیف';
  static const String quantity = 'تعداد';
  static const String unitPrice = 'قیمت واحد';
  static const String discountType = 'نوع تخفیف';
  static const String discountValue = 'مقدار تخفیف';
  static const String discountAmount = 'مبلغ تخفیف';
  static const String lineTotal = 'جمع سطر';
  static const String totalGross = 'جمع کل ناخالص';
  static const String totalDiscount = 'مجموع تخفیفات';
  static const String totalNet = 'مبلغ خالص پرداختی';
  static const String saveInvoice = 'ذخیره فاکتور';
  static const String printInvoice = 'چاپ فاکتور';
  static const String editInvoice = 'ویرایش فاکتور';
  static const String deleteInvoice = 'حذف فاکتور';
  static const String newInvoice = 'فاکتور جدید';

  // ─── Invoice Statuses ───────────────────────────────────────────────
  static const String statusSettled = 'تسویه شده';
  static const String statusPending = 'در انتظار پرداخت';
  static const String statusDeposit = 'بیعانه';
  static const String statusCancelled = 'لغو شده';
  static const List<String> invoiceStatuses = [
    statusPending,
    statusSettled,
    statusDeposit,
    statusCancelled,
  ];

  // ─── Discount Types ─────────────────────────────────────────────────
  static const String discountNone = 'بدون تخفیف';
  static const String discountPercentage = 'درصدی (%)';
  static const String discountFixed = 'مبلغی (تومان)';

  // ─── Dashboard & Reports ────────────────────────────────────────────
  static const String dashboard = 'داشبورد';
  static const String reports = 'گزارشات';
  static const String totalGrossSales = 'فروش ناخالص';
  static const String totalNetRevenue = 'درآمد خالص';
  static const String totalDiscountsGiven = 'تخفیفات ارائه‌شده';
  static const String outstandingInvoices = 'فاکتورهای معلق';
  static const String bestSellers = 'پرفروش‌ترین کالاها';
  static const String salesLedger = 'ریز اقلام فروش رفته';
  static const String exportExcel = 'خروجی اکسل';
  static const String exportCsv = 'خروجی CSV';
  static const String filterByDate = 'فیلتر بر اساس تاریخ';
  static const String filterByCustomer = 'فیلتر بر اساس مشتری';
  static const String filterByStatus = 'فیلتر بر اساس وضعیت';
  static const String fromDate = 'از تاریخ';
  static const String toDate = 'تا تاریخ';
  static const String recentInvoices = 'فاکتورهای اخیر';
  static const String byVolume = 'بر اساس تعداد';
  static const String byRevenue = 'بر اساس درآمد';

  // ─── Actions ────────────────────────────────────────────────────────
  static const String save = 'ذخیره';
  static const String cancel = 'انصراف';
  static const String delete = 'حذف';
  static const String edit = 'ویرایش';
  static const String search = 'جستجو';
  static const String close = 'بستن';
  static const String confirm = 'تأیید';
  static const String yes = 'بله';
  static const String no = 'خیر';
  static const String noData = 'داده‌ای یافت نشد';
  static const String loading = 'در حال بارگذاری...';

  // ─── Validation ─────────────────────────────────────────────────────
  static const String fieldRequired = 'این فیلد الزامی است';
  static const String invalidNumber = 'عدد وارد شده معتبر نیست';
  static const String deleteConfirmTitle = 'تأیید حذف';
  static const String deleteConfirmMessage = 'آیا از حذف این مورد اطمینان دارید؟';

  // ─── Toman suffix ───────────────────────────────────────────────────
  static const String toman = 'تومان';

  // ─── Product Import ─────────────────────────────────────────────────
  static const String importProducts = 'ورود کالا از فایل';
  static const String importFromCsv = 'ورود از CSV';
  static const String importFromExcel = 'ورود از اکسل';
  static const String importSuccess = 'کالاها با موفقیت وارد شدند';

  // ─── Temp/Perm Product ──────────────────────────────────────────────
  static const String createProduct = 'ساخت کالای جدید';
  static const String tempProduct = 'فقط برای این فاکتور';
  static const String permanentProduct = 'ذخیره دائمی';
  static const String productType = 'نوع کالا';

  // ─── Customer Create ────────────────────────────────────────────────
  static const String createNewCustomer = 'ساخت مشتری جدید';
  static const String customerNotFound = 'مشتری یافت نشد، ایجاد کنید';
}
