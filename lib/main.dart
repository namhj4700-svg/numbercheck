import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/personnel.dart';
import 'providers/personnel_provider.dart';
import 'screens/lock_screen.dart';
import 'screens/list_screen.dart';
import 'screens/input_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/trash_screen.dart';

void main() {
  runApp(const MyApp());
}

/// 앱 루트 위젯.
///
/// [PersonnelProvider]를 앱 전체에 제공하고 MaterialApp 을 설정한다.
/// Provider 생성 시 [PersonnelProvider.loadData]를 즉시 호출해
/// 첫 화면이 렌더링되기 전에 저장된 데이터를 불러온다.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PersonnelProvider()..loadData(),
      child: MaterialApp(
        title: 'Personnel Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            primary: Colors.indigo,
            surface: Colors.grey.shade50,
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        // 웹/데스크탑에서 마우스 드래그 스크롤을 허용
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
        ),
        home: const AppHome(),
      ),
    );
  }
}

/// 화면 전환을 담당하는 최상위 위젯.
///
/// [PersonnelProvider.screen] 값을 감시하다가 변경되면
/// [AnimatedSwitcher]를 통해 페이드+슬라이드 전환 애니메이션과 함께
/// 해당 화면 위젯으로 교체한다.
///
/// [KeyedSubtree]로 각 화면에 고유 Key 를 부여해
/// [AnimatedSwitcher]가 화면 교체를 올바르게 감지하도록 한다.
class AppHome extends StatelessWidget {
  const AppHome({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = context.select<PersonnelProvider, Screen>((p) => p.screen);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(screen),
            child: switch (screen) {
              Screen.lock => const LockScreen(),
              Screen.list => const ListScreen(),
              Screen.input => const InputScreen(),
              Screen.settings => const SettingsScreen(),
              Screen.detail => const DetailScreen(),
              Screen.trash => const TrashScreen(),
            },
          ),
        ),
      ),
    );
  }
}
