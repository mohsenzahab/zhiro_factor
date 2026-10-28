/// All user-facing Persian string constants for ZhiroFactor.
class AppStrings {
  AppStrings._();

  // ─── App ────────────────────────────────────────────────────────────
  static const String appTitle = 'ژیروفاکتور';
  static const String appSubtitle = 'مدیریت فروش و فاکتور';

  // ─── Navigation ─────────────────────────────────────────────────────
  static const String navNewInvoice = 'فاکتور جدید';
  static const String navInvoiceHistory = 'تاریخچه فاکتورها';
  static const String navProducts = 'کالاها و خدمات';
  static const String navDemands = 'لیست نیازمندی‌ها';
  static const String navCustomers = 'مشتریان';
  static const String navSuppliers = 'تأمین‌کنندگان';
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
  static const String applyPriceAdjustment = 'اعمال درصد افزایش قیمت';
  static const String priceAdjustmentPercentage = 'درصد تغییر قیمت';
  static const String priceAdjustmentHint = 'مثلاً ۱۰ برای ۱۰٪ افزایش یا -۵ برای ۵٪ کاهش';
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
  static const String statusCredit = 'نسیه';
  static const String statusCancelled = 'لغو شده';
  static const List<String> invoiceStatuses = [
    statusPending,
    statusSettled,
    statusDeposit,
    statusCredit,
    statusCancelled,
  ];

  // ─── Payments & Credit ──────────────────────────────────────────────
  static const String payments = 'دریافتی‌ها';
  static const String paymentsAndCredit = 'دریافتی‌ها و نسیه';
  static const String paidAmount = 'مبلغ دریافتی';
  static const String remainingAmount = 'مانده (نسیه)';
  static const String addPayment = 'ثبت دریافتی';
  static const String newPayment = 'دریافتی جدید';
  static const String paymentDate = 'تاریخ دریافت';
  static const String paymentAmount = 'مبلغ دریافت';
  static const String paymentNote = 'توضیحات / بابت';
  static const String paymentSuccess = 'دریافتی با موفقیت ثبت شد';
  static const String noPayments = 'هیچ دریافتی ثبت نشده است';
  static const String settleAll = 'تسویه کل مانده';

  // ─── Discount Types ─────────────────────────────────────────────────
  static const String discountNone = 'بدون تخفیف';
  static const String discountPercentage = 'درصدی (%)';
  static const String discountFixed = 'مبلغی (تومان)';

  // ─── Dashboard & Reports ────────────────────────────────────────────
  static const String dashboard = 'داشبورد';
  static const String reports = 'گزارشات';
  static const String totalGrossSales = 'فروش ناخالص';
  static const String totalNetRevenue = 'درآمد خالص';
  static const String netProfit = 'سود خالص';
  static const String totalInitialBuyCost = 'مجموع هزینه خرید';
  static const String totalCurrentBuyCost = 'هزینه خرید کنونی';
  static const String profitPercentSales = 'درصد سود از فروش';
  static const String profitPercentCost = 'درصد سود روی خرید';
  static const String discountPercentSales = 'درصد تخفیف از فروش';
  static const String netSalesAfterDiscount = 'فروش پس از تخفیف';
  static const String pendingAndDeposit = 'مطالبات معلق و بیعانه';
  static const String settledDiscounts = 'تخفیفات تسویه‌شده';
  static const String outstandingInvoices = 'فاکتورهای معلق';
  static const String bestSellers = 'پرفروش‌ترین کالاها';
  static const String salesLedger = 'ریز اقلام فروش رفته';
  static const String exportExcel = 'خروجی اکسل';
  static const String exportCsv = 'خروجی CSV';
  static const String exportProducts = 'خروجی فایل کالاها';
  static const String exportProductsExcel = 'خروجی اکسل کالاها';
  static const String exportProductsCsv = 'خروجی CSV کالاها';
  static const String filterByDate = 'فیلتر بر اساس تاریخ';
  static const String filterByCustomer = 'فیلتر بر اساس مشتری';
  static const String filterByStatus = 'فیلتر بر اساس وضعیت';
  static const String fromDate = 'از تاریخ';
  static const String toDate = 'تا تاریخ';
  static const String recentInvoices = 'فاکتورهای اخیر';
  static const String byVolume = 'بر اساس تعداد';
  static const String byRevenue = 'بر اساس درآمد';
  static const String dateRange = 'بازه تاریخ';
  static const String today = 'امروز';
  static const String thisWeek = 'هفته جاری';
  static const String thisMonth = 'ماه جاری';
  static const String allTime = 'کل دوره';
  static const String customRange = 'بازه انتخابی';
  static const String selectDate = 'انتخاب تاریخ';
  static const String rowProfit = 'سود سطر';
  static const String overallDiscount = 'تخفیف کل فاکتور';
  static const String overallDiscountValue = 'مقدار تخفیف کل';
  static const String subtotalBeforeOverallDiscount = 'جمع پس از تخفیف اقلام';
  static const String finalPayable = 'مبلغ نهایی قابل پرداخت';

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

  // ─── Preset Templates (Pre-Invoice) ─────────────────────────────
  static const String presetTemplate = 'پیش‌فاکتور';
  static const String presetTemplates = 'پیش‌فاکتورها';
  static const String loadTemplate = 'بارگذاری پیش‌فاکتور';
  static const String saveAsTemplate = 'ذخیره بعنوان پیش‌فاکتور';
  static const String templateName = 'نام پیش‌فاکتور';
  static const String templateSaved = 'پیش‌فاکتور با موفقیت ذخیره شد';
  static const String templateLoaded = 'اقلام پیش‌فاکتور به فاکتور اضافه شدند';
  static const String deleteTemplate = 'حذف پیش‌فاکتور';
  static const String noTemplates = 'هیچ پیش‌فاکتوری ثبت نشده';
  static const String enterTemplateName = 'نام پیش‌فاکتور را وارد کنید...';
  static const String templateItems = 'اقلام';

  // ─── Settings ──────────────────────────────────────────────────────
  static const String navSettings = 'تنظیمات';
  static const String settings = 'تنظیمات';
  static const String businessProfile = 'پروفایل کسب‌وکار';
  static const String invoiceSettings = 'تنظیمات فاکتور';
  static const String invoiceSettingsSubtitle = 'انتخاب کنید کدام اطلاعات در فاکتور چاپ شود';
  static const String businessName = 'نام فروشگاه / کسب‌وکار';
  static const String businessDescription = 'توضیحات';
  static const String showNameOnInvoice = 'نمایش نام در فاکتور';
  static const String showDescriptionOnInvoice = 'نمایش توضیحات در فاکتور';
  static const String descriptionPosition = 'مکان توضیحات:';
  static const String settingsSaved = 'تنظیمات با موفقیت ذخیره شد';
  static const String businessNameHint = 'مثال: فروشگاه ژیرو';
  static const String businessDescriptionHint = 'آدرس، تلفن، خدمات و هر توضیح دیگر...';
  static const String defaultPageFormat = 'اندازه برگه چاپ پیش‌فرض:';
  static const String pageFormatA4 = 'A4 (استاندارد)';
  static const String pageFormatA5 = 'A5 (دفترچه‌ای)';
  static const String previewInvoice = 'پیش‌نمایش فاکتور';
  static const String quickPrint = 'چاپ فوری';
  static const String savePdf = 'ذخیره فایل PDF';
  static const String pdfSavedSuccess = 'فایل PDF با موفقیت ذخیره شد';
  static const String pdfSaveError = 'خطا در ذخیره فایل PDF';

  // ─── Purchase (خرید) ──────────────────────────────────────────────
  static const String navPurchases = 'خرید کالا';
  static const String purchase = 'خرید';
  static const String purchases = 'خریدها';
  static const String purchaseNumber = 'شماره فاکتور خرید';
  static const String newPurchase = 'خرید جدید';
  static const String purchaseHistory = 'تاریخچه خریدها';
  static const String addPurchase = 'ثبت خرید';
  static const String editPurchase = 'ویرایش خرید';
  static const String deletePurchase = 'حذف خرید';
  static const String savePurchase = 'ذخیره خرید';
  static const String purchaseDate = 'تاریخ خرید';
  static const String shippingCost = 'هزینه ارسال';
  static const String extraCosts = 'هزینه‌های اضافی';
  static const String purchaseTotal = 'جمع فاکتور خرید';
  static const String purchaseNotes = 'یادداشت خرید';
  static const String searchPurchase = 'جستجوی خرید...';
  static const String purchaseSaved = 'خرید با موفقیت ذخیره شد';
  static const String purchaseDeleted = 'خرید حذف شد';
  static const String noPurchases = 'هیچ خریدی ثبت نشده';
  static const String purchaseItemsTotal = 'جمع اقلام';
  static const String purchaseNetTotal = 'مبلغ نهایی';
  static const String relatedPurchases = 'فاکتورهای خرید مرتبط';
  static const String noPurchaseHistory = 'سابقه خریدی برای این کالا ثبت نشده';
  static const String purchasedQty = 'تعداد خریداری شده';

  // ─── Supplier (تأمین‌کننده) ─────────────────────────────────────────
  static const String supplier = 'تأمین‌کننده';
  static const String suppliers = 'تأمین‌کنندگان';
  static const String supplierCode = 'کد تأمین‌کننده';
  static const String supplierName = 'نام تأمین‌کننده';
  static const String supplierPhone = 'تلفن';
  static const String supplierAddress = 'آدرس';
  static const String supplierNotes = 'یادداشت';
  static const String addSupplier = 'افزودن تأمین‌کننده';
  static const String editSupplier = 'ویرایش تأمین‌کننده';
  static const String deleteSupplier = 'حذف تأمین‌کننده';
  static const String selectSupplier = 'انتخاب تأمین‌کننده';
  static const String searchSupplier = 'جستجوی تأمین‌کننده...';
  static const String createNewSupplier = 'ساخت تأمین‌کننده جدید';

  // ─── Purchase Statuses ──────────────────────────────────────────────
  static const String purchaseStatusPending = 'در انتظار پرداخت';
  static const String purchaseStatusSettled = 'تسویه شده';
  static const String purchaseStatusCancelled = 'لغو شده';
  static const List<String> purchaseStatuses = [
    purchaseStatusPending,
    purchaseStatusSettled,
    purchaseStatusCancelled,
  ];

  // ─── Price Change History (تاریخچه تغییرات قیمت) ────────────────────
  static const String priceChangeHistory = 'تاریخچه تغییرات قیمت';
  static const String priceChangeHistorySubtitle = 'سوابق افزایش و کاهش قیمت خرید کالاها';
  static const String oldPrice = 'قیمت قبلی';
  static const String newPrice = 'قیمت جدید';
  static const String priceChangeAmount = 'میزان تغییر';
  static const String priceChangePercent = 'درصد تغییر';
  static const String changeType = 'نوع تغییر';
  static const String changeSource = 'منبع / شرح';
  static const String changeDate = 'تاریخ ثبت';
  static const String allChanges = 'همه تغییرات';
  static const String manualChange = 'ویرایش دستی';
  static const String batchAdjustmentChange = 'تغییر گروهی';
  static const String purchaseChange = 'فاکتور خرید';
  static const String noPriceChangeHistory = 'هیچ سابقه‌ای از تغییر قیمت ثبت نشده است';
  static const String totalPriceChanges = 'تعداد تغییرات';
  static const String averageChangePercent = 'میانگین درصد تغییر';
  static const String maxIncrease = 'بیشترین افزایش';
  static const String maxDecrease = 'بیشترین کاهش';
  static const String priceHistoryForProduct = 'تاریخچه تغییرات قیمت کالا';

  // ─── Product Sales History (تاریخچه فروش کالا) ──────────────────────
  static const String productSalesHistory = 'تاریخچه فروش کالا';
  static const String productSalesHistorySubtitle = 'سوابق و فاکتورهای فروش کالا به مشتریان';
  static const String backToProducts = 'بازگشت به کالاها';
  static const String viewProductSales = 'تاریخچه فروش کالا';
  static const String remainingStock = 'موجودی انبار';
  static const String currentBuyPriceLabel = 'قیمت خرید کنونی';
  static const String currentSellPriceLabel = 'قیمت فروش کنونی';
  static const String totalSoldLabel = 'تعداد کل فروش';
  static const String periodSalesTotal = 'مجموع فروش دوره';
  static const String periodProfitTotal = 'سود دوره';
  static const String periodQuantityTotal = 'تعداد فروش دوره';
  static const String noProductSalesHistory = 'هیچ سابقه فروشی برای این کالا ثبت نشده است';
  static const String searchCustomerOrInvoice = 'جستجوی نام مشتری یا شماره فاکتور...';
  static const String clickToOpenInvoice = 'کلیک برای باز کردن فاکتور';
  static const String exportProductSalesExcel = 'خروجی اکسل تاریخچه فروش';
  static const String exportProductSalesCsv = 'خروجی CSV تاریخچه فروش';
}
