import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mwandu/core/services/sp_service.dart';
import 'package:mwandu/core/theme/variables.dart';
import 'package:mwandu/feature/authentication/bloc/auth_bloc.dart';
import 'package:mwandu/feature/authentication/repository/auth_repository.dart';
import 'package:mwandu/feature/authentication/repository/local_auth_repository.dart';
import 'package:mwandu/feature/authentication/repository/remote_auth_repository.dart';
import 'package:mwandu/feature/authentication/screen/sign_in_screen.dart';
import 'package:mwandu/feature/authentication/screen/sign_up_screen.dart';
import 'package:mwandu/feature/authentication/screen/splash_screen.dart';
import 'package:mwandu/feature/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local storage
  await Hive.initFlutter();
  final userBox = await Hive.openBox(LocalAuthRepository.userBoxName);

  // Initialize SharedPreferences service
  final spService = await SpService.init();

  // Repositories
  final localRepo = LocalAuthRepository(box: userBox, spService: spService);
  final remoteRepo = RemoteAuthRepository();
  final authRepository = AuthRepository(
    remoteRepo: remoteRepo,
    localRepo: localRepo,
  );

  runApp(KilimoApp(authRepository: authRepository));
}

class KilimoApp extends StatefulWidget {
  final AuthRepository authRepository;

  const KilimoApp({super.key, required this.authRepository});

  @override
  State<KilimoApp> createState() => _KilimoAppState();
}

class _KilimoAppState extends State<KilimoApp> {
  late final AppThemeController _themeController;

  @override
  void initState() {
    super.initState();
    // Default to Gray 100 Dark theme matching Carbon design
    _themeController = AppThemeController(AppThemeMode.gray100);
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: widget.authRepository,
      child: BlocProvider(
        create: (context) => AuthBloc(authRepository: widget.authRepository),
        child: AppThemeScope(
          controller: _themeController,
          child: ValueListenableBuilder<AppThemeMode>(
            valueListenable: _themeController,
            builder: (context, activeMode, _) {
              return MaterialApp(
                title: 'Kilimo - Smart Agriculture',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.whiteTheme,
                darkTheme: AppTheme.gray100Theme,
                themeMode: activeMode.isDark ? ThemeMode.dark : ThemeMode.light,
                initialRoute: '/',
                routes: {
                  '/': (context) => const SplashScreen(),
                  '/signin': (context) => const SignInScreen(),
                  '/signup': (context) => const SignUpScreen(),
                  '/home': (context) => const HomeScreen(),
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
