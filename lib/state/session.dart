import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exception.dart';
import '../core/permissions.dart';
import '../core/token_store.dart';
import '../data/directoo_api.dart';
import '../models/models.dart';

enum AuthGate { unauthenticated, profile, knowledge, instagram, ready }

class SessionController extends ChangeNotifier {
  SessionController({required this.api, required this.prefs, required this.tokens});

  final DirectooApi api;
  final SharedPreferences prefs;
  final TokenStore tokens;

  bool booting = true;
  String? bootError;
  AuthGate gate = AuthGate.unauthenticated;
  AuthUser? user;
  List<Workspace> workspaces = const [];
  int? workspaceId;
  bool instagramReviewing = false;
  bool dark = false;

  String? pendingPhone;
  String? maskedPhone;
  int otpExpiresIn = 120;

  bool _running = false;

  Workspace? get workspace {
    for (final item in workspaces) {
      if (item.id == workspaceId) return item;
    }
    return workspaces.isEmpty ? null : workspaces.first;
  }

  WorkspacePermissions get permissions => WorkspacePermissions(workspace?.role);

  bool get introSeen => prefs.getBool('intro_seen') ?? false;

  Future<void> completeIntro() async {
    await prefs.setBool('intro_seen', true);
    notifyListeners();
  }

  void publish() => notifyListeners();

  Future<void> bootstrap() async {
    if (_running) return;
    _running = true;
    booting = true;
    bootError = null;
    dark = prefs.getBool('theme_dark') ?? false;
    notifyListeners();
    try {
      if (!tokens.isAuthenticated) {
        gate = AuthGate.unauthenticated;
        return;
      }
      user = await api.me();
      await _resolveGate();
    } on ApiException catch (error) {
      if (error.status == 401) {
        await tokens.clear();
        user = null;
        workspaces = const [];
        gate = AuthGate.unauthenticated;
      } else {
        bootError = error.message;
      }
    } catch (_) {
      bootError = 'بررسی دسترسی ناموفق بود.';
    } finally {
      booting = false;
      _running = false;
      notifyListeners();
    }
  }

  Future<void> _resolveGate() async {
    final current = user;
    if (current == null) {
      gate = AuthGate.unauthenticated;
      return;
    }
    if (current.profileIncomplete && prefs.getBool('profile_skipped') != true) {
      gate = AuthGate.profile;
      return;
    }
    workspaces = await api.workspaces();
    final saved = prefs.getInt('workspace_id');
    workspaceId = workspaces.any((item) => item.id == saved) ? saved : (workspaces.isEmpty ? null : workspaces.first.id);
    if (workspaceId != null) await prefs.setInt('workspace_id', workspaceId!);

    final ws = workspace;
    final knowledgeDone = prefs.getBool('knowledge_done') == true;
    final knowledgeSkipped = prefs.getBool('knowledge_skipped') == true;
    if (ws != null && !knowledgeDone && !knowledgeSkipped && ws.features.enabled('knowledge_enabled')) {
      try {
        final info = await api.business(ws.id);
        if (info.industry.trim().isEmpty) {
          gate = AuthGate.knowledge;
          return;
        }
        await prefs.setBool('knowledge_done', true);
      } on ApiException {
        gate = AuthGate.knowledge;
        return;
      }
    }

    if (prefs.getBool('instagram_pending') == true && ws != null) {
      final request = await api.accessRequest(ws.id);
      if (request?.status == 'approved') {
        await prefs.remove('instagram_pending');
      } else {
        instagramReviewing = request?.reviewing ?? false;
        gate = AuthGate.instagram;
        return;
      }
    }

    gate = AuthGate.ready;
  }

  Future<void> refreshGate() async {
    bootError = null;
    try {
      if (user == null && tokens.isAuthenticated) user = await api.me();
      await _resolveGate();
    } on ApiException catch (error) {
      if (error.status == 401) {
        await onUnauthorized();
        return;
      }
      bootError = error.message;
    }
    notifyListeners();
  }

  Future<void> sendOtp(String phone) async {
    final result = await api.sendOtp(phone);
    pendingPhone = phone;
    maskedPhone = result.maskedPhone;
    otpExpiresIn = result.expiresIn;
    notifyListeners();
  }

  Future<void> verifyOtp(String otp) async {
    final phone = pendingPhone;
    if (phone == null) throw const ApiException('شماره موبایل پیدا نشد.');
    user = await api.verifyOtp(phone, otp);
    pendingPhone = null;
    await _resolveGate();
    notifyListeners();
  }

  Future<void> skipProfile() async {
    await prefs.setBool('profile_skipped', true);
    await refreshGate();
  }

  Future<void> completeProfile({required String firstName, required String lastName, required String email}) async {
    user = await api.updateProfile(firstName: firstName, lastName: lastName, email: email);
    await prefs.remove('profile_skipped');
    await refreshGate();
  }

  Future<void> skipKnowledge() async {
    await prefs.setBool('knowledge_skipped', true);
    await refreshGate();
  }

  Future<void> finishKnowledge() async {
    await prefs.setBool('knowledge_done', true);
    await prefs.remove('knowledge_skipped');
    await prefs.setBool('instagram_pending', true);
    await refreshGate();
  }

  Future<void> clearInstagramPending() async {
    await prefs.remove('instagram_pending');
    instagramReviewing = false;
    await refreshGate();
  }

  Future<void> selectWorkspace(int id) async {
    workspaceId = id;
    await prefs.setInt('workspace_id', id);
    notifyListeners();
  }

  Future<void> reloadWorkspaces() async {
    workspaces = await api.workspaces();
    if (workspace == null && workspaces.isNotEmpty) {
      workspaceId = workspaces.first.id;
      await prefs.setInt('workspace_id', workspaceId!);
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    dark = !dark;
    await prefs.setBool('theme_dark', dark);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
      await tokens.clear();
    }
    user = null;
    workspaces = const [];
    workspaceId = null;
    gate = AuthGate.unauthenticated;
    instagramReviewing = false;
    await prefs.remove('profile_skipped');
    await prefs.remove('knowledge_done');
    await prefs.remove('knowledge_skipped');
    await prefs.remove('instagram_pending');
    await prefs.remove('workspace_id');
    notifyListeners();
  }

  Future<void> onUnauthorized() async {
    await tokens.clear();
    user = null;
    workspaces = const [];
    gate = AuthGate.unauthenticated;
    booting = false;
    bootError = null;
    notifyListeners();
  }
}
