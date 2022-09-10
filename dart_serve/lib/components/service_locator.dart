import 'kiwi_service_locator.dart';

class ServiceLocator {
  static ServiceLocatorDelegate delegate = KiwiServiceLocator();

  static void registerFactory<T>(InstanceFactory<T> factory) =>
      delegate.registerFactory<T>(factory);

  static T locate<T>() => delegate.locate<T>();

  static T call<T>() => locate<T>();
}

abstract class ServiceLocatorDelegate {
  void registerFactory<T>(InstanceFactory<T> factory);
  T locate<T>();
  T call<T>() => locate<T>();
}

typedef ServiceLocatorFn<T> = T Function();
typedef InstanceFactory<T> = T Function(ServiceLocatorDelegate locate);
