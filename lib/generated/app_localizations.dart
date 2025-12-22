import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dolphin'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhone;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get registerNow;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @websites.
  ///
  /// In en, this message translates to:
  /// **'Websites'**
  String get websites;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get newOrder;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @hotDeals.
  ///
  /// In en, this message translates to:
  /// **'Hot Deals For You'**
  String get hotDeals;

  /// No description provided for @searchWebsites.
  ///
  /// In en, this message translates to:
  /// **'Search websites...'**
  String get searchWebsites;

  /// No description provided for @noWebsitesFound.
  ///
  /// In en, this message translates to:
  /// **'No websites found'**
  String get noWebsitesFound;

  /// No description provided for @dolphinShop.
  ///
  /// In en, this message translates to:
  /// **'Dolphin Shop'**
  String get dolphinShop;

  /// No description provided for @allBrands.
  ///
  /// In en, this message translates to:
  /// **'All Brands'**
  String get allBrands;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @productLink.
  ///
  /// In en, this message translates to:
  /// **'Product Link'**
  String get productLink;

  /// No description provided for @pasteProductLink.
  ///
  /// In en, this message translates to:
  /// **'Paste product link here'**
  String get pasteProductLink;

  /// No description provided for @getDataFromLink.
  ///
  /// In en, this message translates to:
  /// **'Get Data From Link'**
  String get getDataFromLink;

  /// No description provided for @fetchingDetails.
  ///
  /// In en, this message translates to:
  /// **'Fetching product details...'**
  String get fetchingDetails;

  /// No description provided for @productImage.
  ///
  /// In en, this message translates to:
  /// **'Product Image'**
  String get productImage;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @detectedPrice.
  ///
  /// In en, this message translates to:
  /// **'Detected Price'**
  String get detectedPrice;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @selectSize.
  ///
  /// In en, this message translates to:
  /// **'Select Size'**
  String get selectSize;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note (Optional)'**
  String get note;

  /// No description provided for @enterNote.
  ///
  /// In en, this message translates to:
  /// **'Enter any additional notes...'**
  String get enterNote;

  /// No description provided for @charactersRemaining.
  ///
  /// In en, this message translates to:
  /// **'characters remaining'**
  String get charactersRemaining;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @pleaseSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Please select a product image'**
  String get pleaseSelectImage;

  /// No description provided for @pleaseSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Please select a country'**
  String get pleaseSelectCountry;

  /// No description provided for @pleaseSelectSize.
  ///
  /// In en, this message translates to:
  /// **'Please select a size'**
  String get pleaseSelectSize;

  /// No description provided for @orderSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Order submitted successfully!'**
  String get orderSubmitted;

  /// No description provided for @errorSubmittingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error submitting order'**
  String get errorSubmittingOrder;

  /// No description provided for @allOrders.
  ///
  /// In en, this message translates to:
  /// **'All Orders'**
  String get allOrders;

  /// No description provided for @processed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get processed;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @serialNumber.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get serialNumber;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @itemPrice.
  ///
  /// In en, this message translates to:
  /// **'Item Price'**
  String get itemPrice;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @cargo.
  ///
  /// In en, this message translates to:
  /// **'Cargo'**
  String get cargo;

  /// No description provided for @commission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get commission;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @acceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get acceptOrder;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// No description provided for @confirmAccept.
  ///
  /// In en, this message translates to:
  /// **'Confirm Accept'**
  String get confirmAccept;

  /// No description provided for @confirmApprove.
  ///
  /// In en, this message translates to:
  /// **'Confirm Approve'**
  String get confirmApprove;

  /// No description provided for @confirmReject.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reject'**
  String get confirmReject;

  /// No description provided for @areYouSureAccept.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to accept this order?'**
  String get areYouSureAccept;

  /// No description provided for @areYouSureApprove.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this order?'**
  String get areYouSureApprove;

  /// No description provided for @areYouSureReject.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this order?'**
  String get areYouSureReject;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @orderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted successfully!'**
  String get orderAccepted;

  /// No description provided for @orderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order rejected successfully!'**
  String get orderRejected;

  /// No description provided for @errorProcessingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error processing order'**
  String get errorProcessingOrder;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @debtLimit.
  ///
  /// In en, this message translates to:
  /// **'Debt Limit'**
  String get debtLimit;

  /// No description provided for @owedAmount.
  ///
  /// In en, this message translates to:
  /// **'Owed Amount'**
  String get owedAmount;

  /// No description provided for @ordersAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Orders Awaiting Payment'**
  String get ordersAwaitingPayment;

  /// No description provided for @availableCapacity.
  ///
  /// In en, this message translates to:
  /// **'Available Capacity'**
  String get availableCapacity;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @accountLimits.
  ///
  /// In en, this message translates to:
  /// **'Account Limits'**
  String get accountLimits;

  /// No description provided for @financialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get financialSummary;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @totalDeposits.
  ///
  /// In en, this message translates to:
  /// **'Total Deposits'**
  String get totalDeposits;

  /// No description provided for @totalWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'Total Withdrawals'**
  String get totalWithdrawals;

  /// No description provided for @drShipping.
  ///
  /// In en, this message translates to:
  /// **'DR Shipping'**
  String get drShipping;

  /// No description provided for @drsShippingCost.
  ///
  /// In en, this message translates to:
  /// **'DRS Shipping Cost'**
  String get drsShippingCost;

  /// No description provided for @drsCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'DRS Credit Limit'**
  String get drsCreditLimit;

  /// No description provided for @orderStatistics.
  ///
  /// In en, this message translates to:
  /// **'Order Statistics'**
  String get orderStatistics;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @kurdish.
  ///
  /// In en, this message translates to:
  /// **'Kurdish'**
  String get kurdish;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'QTY'**
  String get qty;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @addToOrder.
  ///
  /// In en, this message translates to:
  /// **'Add to Order'**
  String get addToOrder;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @rateOurApp.
  ///
  /// In en, this message translates to:
  /// **'Rate our app'**
  String get rateOurApp;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Logout Confirmation'**
  String get logoutConfirm;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @pleaseCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get pleaseCheckConnection;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get failedToLoadProfile;

  /// No description provided for @noBannersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No banners available'**
  String get noBannersAvailable;

  /// No description provided for @contactFormComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Contact form coming soon!'**
  String get contactFormComingSoon;

  /// No description provided for @ratingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Rating coming soon!'**
  String get ratingComingSoon;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @helpMessage.
  ///
  /// In en, this message translates to:
  /// **'For assistance, please contact our support team.\n\nPhone: +964 750 774 6088\nEmail: support@dolphinshipping.com'**
  String get helpMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @noWebsitesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No websites available'**
  String get noWebsitesAvailable;

  /// No description provided for @notificationsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Notifications coming soon!'**
  String get notificationsComingSoon;

  /// No description provided for @advancedFilterComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Advanced filter coming soon!'**
  String get advancedFilterComingSoon;

  /// No description provided for @goldenprizma.
  ///
  /// In en, this message translates to:
  /// **'Goldenprizma'**
  String get goldenprizma;

  /// Greeting message with user name
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String helloUser(String name);

  /// No description provided for @processingOrder.
  ///
  /// In en, this message translates to:
  /// **'Processing order'**
  String get processingOrder;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @excluded.
  ///
  /// In en, this message translates to:
  /// **'Excluded'**
  String get excluded;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at'**
  String get updatedAt;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @deliveryRequest.
  ///
  /// In en, this message translates to:
  /// **'Delivery Request'**
  String get deliveryRequest;

  /// No description provided for @requestDelivery.
  ///
  /// In en, this message translates to:
  /// **'Request Delivery'**
  String get requestDelivery;

  /// No description provided for @youRequestedDelivery.
  ///
  /// In en, this message translates to:
  /// **'You requested delivery'**
  String get youRequestedDelivery;

  /// No description provided for @youWillGetItASAP.
  ///
  /// In en, this message translates to:
  /// **'You will get it ASAP'**
  String get youWillGetItASAP;

  /// No description provided for @whatsappSupport.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Support'**
  String get whatsappSupport;

  /// No description provided for @ourLocation.
  ///
  /// In en, this message translates to:
  /// **'Our Location'**
  String get ourLocation;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More Options'**
  String get moreOptions;

  /// No description provided for @accountStatement.
  ///
  /// In en, this message translates to:
  /// **'Account Statement'**
  String get accountStatement;

  /// No description provided for @deliveredToErbil.
  ///
  /// In en, this message translates to:
  /// **'Delivered to Erbil'**
  String get deliveredToErbil;

  /// No description provided for @financialSummaryText.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get financialSummaryText;

  /// No description provided for @accountLimitsText.
  ///
  /// In en, this message translates to:
  /// **'Account Limits'**
  String get accountLimitsText;

  /// No description provided for @debtLimitText.
  ///
  /// In en, this message translates to:
  /// **'Debt Limit'**
  String get debtLimitText;

  /// No description provided for @availableCapacityText.
  ///
  /// In en, this message translates to:
  /// **'Available Capacity'**
  String get availableCapacityText;

  /// No description provided for @totalPurchases.
  ///
  /// In en, this message translates to:
  /// **'Total Purchases'**
  String get totalPurchases;

  /// No description provided for @totalPayments.
  ///
  /// In en, this message translates to:
  /// **'Total Payments'**
  String get totalPayments;

  /// No description provided for @contactSupportText.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupportText;

  /// No description provided for @quickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick Links'**
  String get quickLinks;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @deleteAccountFinalConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Final Warning!'**
  String get deleteAccountFinalConfirmTitle;

  /// No description provided for @deleteAccountFinalConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This is your last chance! Once you delete your account, all your data will be permanently removed. Are you sure?'**
  String get deleteAccountFinalConfirmMessage;

  /// No description provided for @yesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete'**
  String get yesDelete;

  /// No description provided for @noCancel.
  ///
  /// In en, this message translates to:
  /// **'No, Cancel'**
  String get noCancel;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account Deleted'**
  String get accountDeleted;

  /// No description provided for @accountDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully deleted. Contact support if you need to reactivate it.'**
  String get accountDeletedMessage;

  /// No description provided for @accountDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Account Deletion Failed'**
  String get accountDeletionFailed;

  /// No description provided for @enterPasswordToDelete.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm deletion'**
  String get enterPasswordToDelete;

  /// No description provided for @pleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please Login'**
  String get pleaseLogin;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to login to access this feature'**
  String get loginRequired;

  /// No description provided for @loginNow.
  ///
  /// In en, this message translates to:
  /// **'Login Now'**
  String get loginNow;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @enterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhoneNumber;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @enterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your address'**
  String get enterYourAddress;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @nameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMustBeAtLeast2Characters;

  /// No description provided for @pleaseEnterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterYourPhoneNumber;

  /// No description provided for @pleaseEnterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be exactly 11 digits'**
  String get pleaseEnterValidPhoneNumber;

  /// No description provided for @pleaseEnterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter your address'**
  String get pleaseEnterYourAddress;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMustBeAtLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6Characters;

  /// No description provided for @pleaseEnterPhoneAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number and password'**
  String get pleaseEnterPhoneAndPassword;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account Created!'**
  String get accountCreated;

  /// No description provided for @accountCreatedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created successfully!\n\nAn admin will activate your account ASAP. You will be notified once your account is active.'**
  String get accountCreatedSuccessMessage;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAnAccount;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password and choose a new password to secure your account.'**
  String get changePasswordDescription;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get enterCurrentPassword;

  /// No description provided for @pleaseEnterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get pleaseEnterCurrentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get enterNewPassword;

  /// No description provided for @pleaseEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your new password'**
  String get pleaseEnterNewPassword;

  /// No description provided for @passwordMustBeAtLeast4Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 4 characters'**
  String get passwordMustBeAtLeast4Characters;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @enterConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get enterConfirmPassword;

  /// No description provided for @pleaseEnterConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseEnterConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @failedToChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get failedToChangePassword;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @passwordTips.
  ///
  /// In en, this message translates to:
  /// **'Password Tips'**
  String get passwordTips;

  /// No description provided for @passwordTip1.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 4 characters long'**
  String get passwordTip1;

  /// No description provided for @passwordTip2.
  ///
  /// In en, this message translates to:
  /// **'Use a strong password to protect your account'**
  String get passwordTip2;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
