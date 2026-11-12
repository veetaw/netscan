import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core/deep_link.dart';
import 'inventory/controller.dart';
import 'l10n/strings.dart';
import 'ui/check_page.dart';
import 'ui/inventory_page.dart';
import 'ui/privacy_button.dart';
import 'ui/security_guide.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NetscanApp());
}

class NetscanApp extends StatefulWidget {
  const NetscanApp({
    super.key,
    this.locale,
    this.initialTab = 0,
    this.restoreInventory = true,
  });
  final Locale? locale;
  final int initialTab;
  final bool restoreInventory;
  @override
  State<NetscanApp> createState() => _NetscanAppState();
}

class _NetscanAppState extends State<NetscanApp> {
  Locale? _locale;
  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Netscan',
    locale: _locale,
    supportedLocales: const [Locale('en'), Locale('it')],
    localeResolutionCallback: (locale, supported) =>
        Locale(locale?.languageCode == 'it' ? 'it' : 'en'),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff17654b),
        surface: const Color(0xfff7f8f4),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: _Home(
      initialTab: widget.initialTab,
      restoreInventory: widget.restoreInventory,
      changeLocale: (locale) => setState(() => _locale = locale),
    ),
  );
}

class _Home extends StatefulWidget {
  const _Home({
    required this.initialTab,
    required this.restoreInventory,
    required this.changeLocale,
  });
  final int initialTab;
  final bool restoreInventory;
  final ValueChanged<Locale> changeLocale;
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final _inventory = InventoryController();
  final _confirmed = <String>{};
  StreamSubscription<Uri>? _links;
  late int _tab;
  String _host = '';
  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    if (widget.restoreInventory) _inventory.restore();
    if (!kIsWeb && widget.restoreInventory) {
      _links = AppLinks().uriLinkStream.listen((uri) {
        final host = hostFromLink(uri);
        if (host != null && mounted) _inspect(host);
      }, onError: (Object error) {});
    }
  }

  void _inspect(String host) => setState(() {
    _host = host;
    _tab = 1;
  });
  @override
  void dispose() {
    _links?.cancel();
    _inventory.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('netscan'),
      actions: [
        PopupMenuButton<Locale>(
          tooltip: tr(context, 'app.language'),
          icon: const Icon(Icons.language),
          onSelected: widget.changeLocale,
          itemBuilder: (_) => const [
            PopupMenuItem(value: Locale('en'), child: Text('English')),
            PopupMenuItem(value: Locale('it'), child: Text('Italiano')),
          ],
        ),
        const PrivacyButton(),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: IndexedStack(
          index: _tab,
          children: [
            InventoryPage(inventory: _inventory, inspect: _inspect),
            CheckPage(
              key: ValueKey(_host),
              initialHost: _host,
              onReport: _inventory.addReport,
            ),
            ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SecurityGuide(
                  confirmed: _confirmed,
                  onChanged: (id, value) => setState(() {
                    if (value) {
                      _confirmed.add(id);
                    } else {
                      _confirmed.remove(id);
                    }
                  }),
                  open: (uri) async {
                    try {
                      await launchUrl(uri);
                    } catch (_) {
                      /* Source remains visible in documentation. */
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (v) => setState(() => _tab = v),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.devices),
          label: tr(context, 'app.inventory'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.manage_search),
          label: tr(context, 'app.check'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.shield_outlined),
          label: tr(context, 'app.guide'),
        ),
      ],
    ),
  );
}
