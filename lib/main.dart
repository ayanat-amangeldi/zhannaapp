import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language.dart';
import 'content.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'shopping.dart';
import 'participant_accounts.dart';
import 'marathon_streams.dart';
import 'screens/participant_access_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/materials_screen.dart';

const burgundy = Color(0xFF75354A);
const cream = Color(0xFFFAF4EC);
const ink = Color(0xFF272019);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(ZhannaApp(controller: LanguageController(preferences: preferences)));
}

class ZhannaApp extends StatefulWidget {
  const ZhannaApp({super.key, this.controller});
  final LanguageController? controller;
  @override
  State<ZhannaApp> createState() => _ZhannaAppState();
}

class _ZhannaAppState extends State<ZhannaApp> {
  late final controller = widget.controller ?? LanguageController();
  late final accounts = ParticipantAccounts(controller.preferences);
  late final streams = MarathonStreams(controller.preferences);
  late final content = ContentStore(controller.preferences);
  late final shopping = ShoppingController(
    controller.preferences,
    content: content,
  );
  Widget _welcome() => WelcomeScreen(
    accounts: accounts,
    streams: streams,
    participantHome: _participantHome,
  );

  Route<void>? _invitationRoute(String name) {
    final token = invitationToken(name, platformRoute: true);
    if (kReleaseMode || token == null) return null;
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: invitationPath),
      builder: (_) => LoginScreen(
        accounts: accounts,
        streams: streams,
        participantHome: _participantHome,
        initialInvitationToken: token,
      ),
    );
  }

  Widget _participantHome(BuildContext context, Participant participant) =>
      ParticipantAccessScreen(
        participant: participant,
        streams: streams,
        marathon: (stream) =>
            AppShell(participantName: participant.name, stream: stream),
      );

  @override
  void dispose() {
    shopping.dispose();
    accounts.dispose();
    streams.dispose();
    content.dispose();
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ContentScope(
    store: content,
    child: ShoppingScope(
      controller: shopping,
      child: LanguageScope(
        controller: controller,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => MaterialApp(
            locale: Locale(controller.value.name),
            supportedLocales: const [Locale('ru'), Locale('kk')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            title: 'KEZEK SENDE',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: cream,
              colorScheme: ColorScheme.fromSeed(
                seedColor: burgundy,
                primary: burgundy,
                surface: const Color(0xFFFFFCF8),
                onSurface: ink,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: cream,
                centerTitle: false,
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              navigationBarTheme: const NavigationBarThemeData(
                backgroundColor: Color(0xFFFFFCF8),
                indicatorColor: Color(0xFFF1DFE3),
              ),
            ),
            routes: {Navigator.defaultRouteName: (_) => _welcome()},
            onGenerateRoute: (settings) =>
                _invitationRoute(settings.name ?? ''),
            onGenerateInitialRoutes: (name) => [
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: Navigator.defaultRouteName),
                builder: (_) => _welcome(),
              ),
              ?_invitationRoute(name),
            ],
          ),
        ),
      ),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.participantName, this.stream});
  final String participantName;
  final MarathonStream? stream;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'KEZEK SENDE',
        style: TextStyle(
          fontSize: 15,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
          color: burgundy,
        ),
      ),
      actions: const [LanguageSwitch()],
    ),
    body: IndexedStack(
      index: index,
      children: [
        HomeScreen(
          name: widget.participantName,
          stream: widget.stream,
          onMenu: () => setState(() => index = 1),
        ),
        MenuScreen(mealIds: widget.stream?.mealIds),
        MaterialsScreen(videoIds: widget.stream?.videoIds),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: context.tr('Главная', 'Басты бет'),
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_rounded),
          label: context.tr('Меню', 'Мәзір'),
        ),
        NavigationDestination(
          icon: Icon(Icons.play_circle_outline),
          selectedIcon: Icon(Icons.play_circle),
          label: context.tr('Уроки', 'Сабақтар'),
        ),
      ],
    ),
  );
}
