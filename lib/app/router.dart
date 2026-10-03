import 'package:go_router/go_router.dart';
import 'package:openscan/features/library/presentation/home_page.dart';
import 'package:openscan/features/settings/presentation/settings_page.dart';
import 'package:openscan/features/viewer/presentation/crop_editor_page.dart';
import 'package:openscan/features/viewer/presentation/document_viewer_page.dart';

/// Rutas v1. `ocr/` y `export/` no tienen pantalla (ARCHITECTURE §4).
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/viewer',
      builder: (context, state) => const DocumentViewerPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/crop',
      builder: (context, state) {
        final index = state.extra! as int;
        return CropEditorPage(index: index);
      },
    ),
  ],
);
