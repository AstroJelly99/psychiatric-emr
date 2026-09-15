import 'package:flutter/material.dart';
import 'package:emr_homemade/domain/appbar/appbar_provider.dart';
import 'package:emr_homemade/domain/drug_interaction/drug_interaction_provider.dart';
import 'package:emr_homemade/presentation/drug_interaction/drug_interaction_button.dart';
import 'package:emr_homemade/presentation/drug_interaction/drug_interaction_manager.dart';
import 'package:emr_homemade/presentation/panel/panel_page.dart';
import 'package:emr_homemade/utils/auth_service.dart';
import 'package:emr_homemade/utils/routes.dart';
import 'package:emr_homemade/utils/session_timeout.dart';
import 'package:emr_homemade/utils/nav_service.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'presentation/login/login_page.dart'; // Hapus import home_page.dart
import 'utils/widgets/appbar.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppBarProvider()),
        ChangeNotifierProvider(create: (_) => DrugInteractionProvider()),
      ],
      // SessionGuard mengawasi idle-timeout dan mengakhiri sesi yang
      // menganggur; router tidak perlu diberi tahu — logout memicu
      // onAuthStateChange, yang sudah didengarkan AuthStateNotifier.
      child: SessionGuard(
        child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'EMR Homemade', // muncul di task switcher Android
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSwatch(
            backgroundColor: Colors.white,
            primarySwatch: Colors.blue,
          ).copyWith(
            surface: Colors.white,
          ),
          textTheme: GoogleFonts.nunitoTextTheme(
            Theme.of(context).textTheme.copyWith(
                  bodyMedium: GoogleFonts.nunito(fontSize: 16),
                  titleMedium: GoogleFonts.nunito(fontSize: 16),
                  labelMedium: GoogleFonts.nunito(fontSize: 16),
                ),
          ),
          scaffoldBackgroundColor: whitePrimary,
        ),
        routerConfig: _router,
        ),
      ),
    );
  }
}

final GlobalKey<ScaffoldState> _appBarScaffoldKey = GlobalKey<ScaffoldState>();

final _router = GoRouter(
  initialLocation: Routes.login,
  // refreshListenable re-evaluasi redirect tiap status sesi berubah, bukan
  // cuma saat navigasi — sesi yang berakhir di tengah pemakaian langsung
  // memulangkan ke login, bukan membiarkan UI terbuka dengan query ditolak RLS.
  refreshListenable: AuthStateNotifier(),
  redirect: (context, state) {
    final isLoggedIn = AuthService.isLoggedIn;
    final isGoingToLogin = state.uri.toString() == Routes.login;

    if (!isLoggedIn && !isGoingToLogin) {
      return Routes.login;
    } else if (isLoggedIn && isGoingToLogin) {
      return Routes.panel;
    }
    return null;
  },
  navigatorKey: NavService.navKey,
  routes: [
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const LoginPage(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      pageBuilder: (context, state, child) {
        return CustomTransitionPage(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AppBarProvider()),
              ChangeNotifierProvider(create: (_) => DrugInteractionProvider()),
            ],
            child: Consumer<AppBarProvider>(builder: (context, prov, _) {
              return Scaffold(
                key: _appBarScaffoldKey,
                appBar: mainAppBar(
                  context,
                  prov,
                  onAccountPressed: () => prov.logout(context),
                ),
                body: Stack(
                  children: [
                    child,
                    const DrugInteractionButton(),
                    const DrugInteractionManager(),
                  ],
                ),
              );
            }),
          ),
          transitionsBuilder: (BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child) =>
              FadeTransition(opacity: animation, child: child),
        );
      },
      routes: [
        GoRoute(
          path: Routes.panel,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PanelPage()),
        ),
      ],
    ),
  ],
);
