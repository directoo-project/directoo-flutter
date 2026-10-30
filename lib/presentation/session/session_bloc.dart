// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_exception.dart';
import '../../core/logging/app_log.dart';
import '../../core/permissions.dart';
import '../../core/token_store.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/instagram_repository.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../../domain/repositories/workspace_repository.dart';
import 'session_event.dart';
import 'session_state.dart';

export 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({
    required AuthRepository auth,
    required WorkspaceRepository workspaces,
    required KnowledgeRepository knowledge,
    required InstagramRepository instagram,
    required SharedPreferences prefs,
    required TokenStore tokens,
  })  : _auth = auth,
        _workspaces = workspaces,
        _knowledge = knowledge,
        _instagram = instagram,
        _prefs = prefs,
        _tokens = tokens,
        super(const SessionState()) {
    on<SessionBootstrapRequested>(_onBootstrap);
    on<SessionIntroCompleted>(_onIntro);
    on<SessionOtpRequested>(_onOtpRequested);
    on<SessionOtpVerified>(_onOtpVerified);
    on<SessionProfileSkipped>(_onProfileSkipped);
    on<SessionProfileCompleted>(_onProfileCompleted);
    on<SessionKnowledgeSkipped>(_onKnowledgeSkipped);
    on<SessionKnowledgeFinished>(_onKnowledgeFinished);
    on<SessionInstagramPendingCleared>(_onInstagramCleared);
    on<SessionInstagramSetupOpened>(_onInstagramSetup);
    on<SessionInstagramReviewingMarked>(_onInstagramReviewing);
    on<SessionWorkspaceSelected>(_onWorkspaceSelected);
    on<SessionWorkspacesReloaded>(_onWorkspacesReloaded);
    on<SessionThemeToggled>(_onTheme);
    on<SessionLogoutRequested>(_onLogout);
    on<SessionUnauthorized>(_onUnauthorized);
    on<SessionGateRefreshRequested>(_onRefreshGate);
  }

  final AuthRepository _auth;
  final WorkspaceRepository _workspaces;
  final KnowledgeRepository _knowledge;
  final InstagramRepository _instagram;
  final SharedPreferences _prefs;
  final TokenStore _tokens;
  var _running = false;

  List<Workspace> get workspaces => state.workspaces;

  bool get booting => state.booting;
  String? get bootError => state.bootError;
  AuthGate get gate => state.gate;
  AuthUser? get user => state.user;
  int? get workspaceId => state.workspaceId;
  Workspace? get workspace => state.workspace;
  WorkspacePermissions get permissions => state.permissions;
  bool get introSeen => state.introSeen;
  bool get instagramReviewing => state.instagramReviewing;
  String? get pendingPhone => state.pendingPhone;
  String? get maskedPhone => state.maskedPhone;
  int get otpExpiresIn => state.otpExpiresIn;
  bool get dark => state.dark;

  Future<void> bootstrap() => _dispatch(SessionBootstrapRequested());
  Future<void> completeIntro() => _dispatch(SessionIntroCompleted());
  Future<void> sendOtp(String phone) => _dispatch(SessionOtpRequested(phone));
  Future<void> verifyOtp(String otp) => _dispatch(SessionOtpVerified(otp));
  Future<void> skipProfile() => _dispatch(SessionProfileSkipped());
  Future<void> completeProfile({required String firstName, required String lastName, required String email}) {
    return _dispatch(SessionProfileCompleted(firstName: firstName, lastName: lastName, email: email));
  }

  Future<void> skipKnowledge() => _dispatch(SessionKnowledgeSkipped());
  Future<void> finishKnowledge() => _dispatch(SessionKnowledgeFinished());
  Future<void> clearInstagramPending() => _dispatch(SessionInstagramPendingCleared());
  Future<void> openInstagramSetup({required bool reviewing}) => _dispatch(SessionInstagramSetupOpened(reviewing: reviewing));
  Future<void> markInstagramReviewing() => _dispatch(SessionInstagramReviewingMarked());
  Future<void> selectWorkspace(int id) => _dispatch(SessionWorkspaceSelected(id));
  Future<void> reloadWorkspaces() => _dispatch(SessionWorkspacesReloaded());
  Future<void> toggleTheme() => _dispatch(SessionThemeToggled());
  Future<void> logout() => _dispatch(SessionLogoutRequested());
  void onUnauthorized() => add(SessionUnauthorized());
  Future<void> refreshGate() => _dispatch(SessionGateRefreshRequested());

  Future<void> _dispatch(SessionEvent event) {
    add(event);
    return event.completer.future;
  }

  Future<void> _run(SessionEvent event, Future<void> Function() body) async {
    try {
      await body();
      if (!event.completer.isCompleted) event.completer.complete();
    } catch (error, stack) {
      AppLog.bloc('fail $event $error');
      if (!event.completer.isCompleted) event.completer.completeError(error, stack);
    }
  }

  Future<void> _onBootstrap(SessionBootstrapRequested event, Emitter<SessionState> emit) {
    return _run(event, () async {
      if (_running) return;
      _running = true;
      emit(state.copyWith(
        booting: true,
        clearBootError: true,
        dark: _prefs.getBool('theme_dark') ?? false,
        introSeen: _prefs.getBool('intro_seen') ?? false,
      ));
      try {
        if (!_tokens.isAuthenticated) {
          emit(state.copyWith(gate: AuthGate.unauthenticated));
          return;
        }
        final user = await _auth.me();
        final resolved = await _resolveGate(state.copyWith(user: user));
        emit(resolved);
      } on ApiException catch (error) {
        if (error.status == 401) {
          await _tokens.clear();
          emit(state.copyWith(clearUser: true, workspaces: const [], clearWorkspaceId: true, gate: AuthGate.unauthenticated));
        } else {
          emit(state.copyWith(bootError: error.message));
        }
      } catch (_) {
        emit(state.copyWith(bootError: 'بررسی دسترسی ناموفق بود.'));
      } finally {
        _running = false;
        emit(state.copyWith(booting: false));
      }
    });
  }

  Future<SessionState> _resolveGate(SessionState current) async {
    final user = current.user;
    if (user == null) return current.copyWith(gate: AuthGate.unauthenticated);
    if (user.profileIncomplete && _prefs.getBool('profile_skipped') != true) {
      return current.copyWith(gate: AuthGate.profile);
    }
    final workspaces = await _workspaces.workspaces();
    final saved = _prefs.getInt('workspace_id');
    final workspaceId = workspaces.any((item) => item.id == saved) ? saved : (workspaces.isEmpty ? null : workspaces.first.id);
    if (workspaceId != null) await _prefs.setInt('workspace_id', workspaceId);
    var next = current.copyWith(workspaces: workspaces, workspaceId: workspaceId, clearWorkspaceId: workspaceId == null);
    final ws = next.workspace;
    final knowledgeDone = _prefs.getBool('knowledge_done') == true;
    final knowledgeSkipped = _prefs.getBool('knowledge_skipped') == true;
    if (ws != null && !knowledgeDone && !knowledgeSkipped && ws.features.enabled('knowledge_enabled')) {
      try {
        final info = await _knowledge.business(ws.id);
        if (info.industry.trim().isEmpty) return next.copyWith(gate: AuthGate.knowledge);
        await _prefs.setBool('knowledge_done', true);
      } on ApiException {
        return next.copyWith(gate: AuthGate.knowledge);
      }
    }
    if (_prefs.getBool('instagram_pending') == true && ws != null) {
      final request = await _instagram.accessRequest(ws.id);
      if (request?.status == 'approved') {
        await _prefs.remove('instagram_pending');
      } else {
        return next.copyWith(instagramReviewing: request?.reviewing ?? false, gate: AuthGate.instagram);
      }
    }
    return next.copyWith(gate: AuthGate.ready, instagramReviewing: false);
  }

  Future<void> _onRefreshGate(SessionGateRefreshRequested event, Emitter<SessionState> emit) {
    return _run(event, () async {
      emit(state.copyWith(clearBootError: true));
      try {
        var current = state;
        if (current.user == null && _tokens.isAuthenticated) {
          current = current.copyWith(user: await _auth.me());
        }
        emit(await _resolveGate(current));
      } on ApiException catch (error) {
        if (error.status == 401) {
          await _clearAuth(emit);
          return;
        }
        emit(state.copyWith(bootError: error.message));
      }
    });
  }

  Future<void> _onIntro(SessionIntroCompleted event, Emitter<SessionState> emit) {
    return _run(event, () async {
      await _prefs.setBool('intro_seen', true);
      emit(state.copyWith(introSeen: true));
    });
  }

  Future<void> _onOtpRequested(SessionOtpRequested event, Emitter<SessionState> emit) {
    return _run(event, () async {
      final result = await _auth.sendOtp(event.phone);
      emit(state.copyWith(pendingPhone: event.phone, maskedPhone: result.maskedPhone, otpExpiresIn: result.expiresIn));
    });
  }

  Future<void> _onOtpVerified(SessionOtpVerified event, Emitter<SessionState> emit) {
    return _run(event, () async {
      final phone = state.pendingPhone;
      if (phone == null) throw const ApiException('شماره موبایل پیدا نشد.');
      final user = await _auth.verifyOtp(phone, event.otp);
      emit(await _resolveGate(state.copyWith(user: user, clearPendingPhone: true)));
    });
  }

  Future<void> _onProfileSkipped(SessionProfileSkipped event, Emitter<SessionState> emit) {
    return _run(event, () async {
      await _prefs.setBool('profile_skipped', true);
      emit(state.copyWith(clearBootError: true));
      emit(await _resolveGate(state));
    });
  }

  Future<void> _onProfileCompleted(SessionProfileCompleted event, Emitter<SessionState> emit) {
    return _run(event, () async {
      final user = await _auth.updateProfile(firstName: event.firstName, lastName: event.lastName, email: event.email);
      await _prefs.remove('profile_skipped');
      emit(await _resolveGate(state.copyWith(user: user, clearBootError: true)));
    });
  }

  Future<void> _onKnowledgeSkipped(SessionKnowledgeSkipped event, Emitter<SessionState> emit) {
    return _run(event, () async {
      await _prefs.setBool('knowledge_skipped', true);
      emit(await _resolveGate(state.copyWith(clearBootError: true)));
    });
  }

  Future<void> _onKnowledgeFinished(SessionKnowledgeFinished event, Emitter<SessionState> emit) {
    return _run(event, () async {
      await _prefs.setBool('knowledge_done', true);
      await _prefs.remove('knowledge_skipped');
      await _prefs.setBool('instagram_pending', true);
      emit(await _resolveGate(state.copyWith(clearBootError: true)));
    });
  }

  Future<void> _onInstagramCleared(SessionInstagramPendingCleared event, Emitter<SessionState> emit) {
    return _run(event, () async {
      await _prefs.remove('instagram_pending');
      emit(await _resolveGate(state.copyWith(instagramReviewing: false, clearBootError: true)));
    });
  }

  Future<void> _onInstagramSetup(SessionInstagramSetupOpened event, Emitter<SessionState> emit) {
    return _run(event, () async {
      await _prefs.setBool('instagram_pending', true);
      emit(state.copyWith(instagramReviewing: event.reviewing, gate: AuthGate.instagram));
    });
  }

  Future<void> _onInstagramReviewing(SessionInstagramReviewingMarked event, Emitter<SessionState> emit) {
    return _run(event, () async {
      emit(state.copyWith(instagramReviewing: true));
    });
  }

  Future<void> _onWorkspaceSelected(SessionWorkspaceSelected event, Emitter<SessionState> emit) {
    return _run(event, () async {
      await _prefs.setInt('workspace_id', event.id);
      emit(state.copyWith(workspaceId: event.id));
    });
  }

  Future<void> _onWorkspacesReloaded(SessionWorkspacesReloaded event, Emitter<SessionState> emit) {
    return _run(event, () async {
      final workspaces = await _workspaces.workspaces();
      var next = state.copyWith(workspaces: workspaces);
      if (next.workspace == null && workspaces.isNotEmpty) {
        await _prefs.setInt('workspace_id', workspaces.first.id);
        next = next.copyWith(workspaceId: workspaces.first.id);
      }
      emit(next);
    });
  }

  Future<void> _onTheme(SessionThemeToggled event, Emitter<SessionState> emit) {
    return _run(event, () async {
      final dark = !state.dark;
      await _prefs.setBool('theme_dark', dark);
      emit(state.copyWith(dark: dark));
    });
  }

  Future<void> _onLogout(SessionLogoutRequested event, Emitter<SessionState> emit) {
    return _run(event, () async {
      try {
        await _auth.logout();
      } catch (_) {
        await _tokens.clear();
      }
      await _clearLocalPrefs();
      emit(SessionState(booting: false, introSeen: state.introSeen, dark: state.dark));
    });
  }

  Future<void> _onUnauthorized(SessionUnauthorized event, Emitter<SessionState> emit) {
    return _run(event, () => _clearAuth(emit));
  }

  Future<void> _clearAuth(Emitter<SessionState> emit) async {
    await _tokens.clear();
    emit(SessionState(booting: false, introSeen: state.introSeen, dark: state.dark));
  }

  Future<void> _clearLocalPrefs() async {
    await _prefs.remove('profile_skipped');
    await _prefs.remove('knowledge_done');
    await _prefs.remove('knowledge_skipped');
    await _prefs.remove('instagram_pending');
    await _prefs.remove('workspace_id');
  }
}
