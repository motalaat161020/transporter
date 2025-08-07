abstract class AppRoutes {
  // Routes العامة
  static const SPLASH = '/splash';
  static const USER_TYPE_SELECTION = '/user-type-selection';
  static const PHONE_AUTH = '/phone-auth';
  static const VERIFY_OTP = '/verify-otp';
  static const COMPLETE_PROFILE = '/complete-profile';
  
  // Routes الراكب (Rider)
  static const RIDER_HOME = '/rider/home';
  static const RIDER_PROFILE = '/rider/profile';
  static const RIDER_TRIP_HISTORY = '/rider/trip-history';
  static const RIDER_WALLET = '/rider/wallet';
  static const RIDER_ADD_BALANCE = '/rider/add-balance';
  static const RIDER_SETTINGS = '/rider/settings';
  static const RIDER_ABOUT = '/rider/about';
  static const RIDER_NOTIFICATIONS = '/rider/notifications';
  static const RIDER_BOOK_TRIP = '/rider/book-trip';
  static const RIDER_TRIP_TRACKING = '/rider/trip-tracking';
  
  // Routes السائق (Driver)
  static const DRIVER_HOME = '/driver/home';
  static const DRIVER_PROFILE = '/driver/profile';
  static const DRIVER_TRIP_HISTORY = '/driver/trip-history';
  static const DRIVER_WALLET = '/driver/wallet';
  static const DRIVER_SETTINGS = '/driver/settings';
  static const DRIVER_NOTIFICATIONS = '/driver/notifications';
  static const DRIVER_TRIP_DETAILS = '/driver/trip-details';
}