import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/services/analytics_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/navigation/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: CountryFlourApp()));
}

class CountryFlourApp extends ConsumerStatefulWidget {
  const CountryFlourApp({super.key});

  @override
  ConsumerState<CountryFlourApp> createState() => _CountryFlourAppState();
}

class _CountryFlourAppState extends ConsumerState<CountryFlourApp> {
  GoRouter? _router;

  // Map route paths → human-readable GA screen names
  String _screenName(String path) {
    if (path.startsWith('/product/')) return 'product_detail';
    if (path.startsWith('/combo/')) return 'combo_detail';
    const names = {
      '/login': 'login',
      '/home': 'home',
      '/products': 'products',
      '/cart': 'cart',
      '/checkout': 'checkout',
      '/orders': 'orders',
      '/profile': 'profile',
      '/addresses': 'addresses',
    };
    return names[path] ?? path;
  }

  void _onRouteChanged() {
    if (!mounted || _router == null) return;
    final path = _router!.routeInformationProvider.value.uri.path;
    AnalyticsService.logScreenView(_screenName(path));
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Wire router listener once (guard against re-wiring on rebuild)
    if (_router != router) {
      _router?.routeInformationProvider.removeListener(_onRouteChanged);
      _router = router;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _router?.routeInformationProvider.addListener(_onRouteChanged);
      });
    }

    return MaterialApp.router(
      title: 'Country Flour',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1).clamp(0.85, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
