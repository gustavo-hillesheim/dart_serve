import 'package:kiwi/kiwi.dart';

import 'service_locator.dart';

class KiwiServiceLocator extends ServiceLocatorDelegate {
  final _container = KiwiContainer();

  @override
  T locate<T>() => _container.resolve<T>();

  @override
  void registerFactory<T>(InstanceFactory<T> factory) =>
      _container.registerSingleton((_) => factory(this));

  @override
  void clear() => _container.clear();
}
