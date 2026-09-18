// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/budget_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/home/home_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    debug: false,
  );

  runApp(const BudgetTrackerApp());
}

class BudgetTrackerApp extends StatelessWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = BudgetRepository();

    return MultiRepositoryProvider(
      providers: [RepositoryProvider<BudgetRepository>.value(value: repo)],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<AuthBloc>(
              create: (_) => AuthBloc(repo)..add(AuthStarted())),
          BlocProvider<HomeBloc>(create: (_) => HomeBloc(repo)),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (ctx, themeMode) {
            // Keep status bar icons consistent with theme
            final isDark = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(ctx) == Brightness.dark);
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ));

            return MaterialApp(
              title: AppConstants.appName,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              debugShowCheckedModeBanner: false,
              home: const _AppRouter(),
            );
          },
        ),
      ),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthBlocState>(
      buildWhen: (prev, curr) =>
          (prev is AuthAuthenticated) != (curr is AuthAuthenticated) ||
          prev is AuthInitial,
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          final now = DateTime.now();
          ctx.read<HomeBloc>().add(HomeLoad(month: now.month, year: now.year));
        }
      },
      builder: (ctx, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const _SplashScreen();
        }
        if (state is AuthAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final bg = context.bgColor;
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 8))
                ],
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 42)),
          const SizedBox(height: 20),
          Text('Budget Tracker App',
              style: TextStyle(
                  color: context.txtPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Track smarter, save better',
              style: TextStyle(color: context.txtSecondary, fontSize: 14)),
          const SizedBox(height: 52),
          const CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ]),
      ),
    );
  }
}
