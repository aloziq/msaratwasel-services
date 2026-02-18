import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:msaratwasel_services/core/di/injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // default
)
Future<GetIt> configureDependencies() => getIt.init();
