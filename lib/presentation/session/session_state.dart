import '../../core/permissions.dart';
import '../../domain/entities/models.dart';

enum AuthGate { unauthenticated, profile, knowledge, instagram, ready }

class SessionState {
  const SessionState({
    this.booting = true,
    this.bootError,
    this.gate = AuthGate.unauthenticated,
    this.user,
    this.workspaces = const [],
    this.workspaceId,
    this.instagramReviewing = false,
    this.dark = false,
    this.pendingPhone,
    this.maskedPhone,
    this.otpExpiresIn = 120,
    this.introSeen = false,
  });

  final bool booting;
  final String? bootError;
  final AuthGate gate;
  final AuthUser? user;
  final List<Workspace> workspaces;
  final int? workspaceId;
  final bool instagramReviewing;
  final bool dark;
  final String? pendingPhone;
  final String? maskedPhone;
  final int otpExpiresIn;
  final bool introSeen;

  Workspace? get workspace {
    for (final item in workspaces) {
      if (item.id == workspaceId) return item;
    }
    return workspaces.isEmpty ? null : workspaces.first;
  }

  WorkspacePermissions get permissions => WorkspacePermissions(workspace?.role);

  SessionState copyWith({
    bool? booting,
    String? bootError,
    bool clearBootError = false,
    AuthGate? gate,
    AuthUser? user,
    bool clearUser = false,
    List<Workspace>? workspaces,
    int? workspaceId,
    bool clearWorkspaceId = false,
    bool? instagramReviewing,
    bool? dark,
    String? pendingPhone,
    bool clearPendingPhone = false,
    String? maskedPhone,
    bool clearMaskedPhone = false,
    int? otpExpiresIn,
    bool? introSeen,
  }) {
    return SessionState(
      booting: booting ?? this.booting,
      bootError: clearBootError ? null : (bootError ?? this.bootError),
      gate: gate ?? this.gate,
      user: clearUser ? null : (user ?? this.user),
      workspaces: workspaces ?? this.workspaces,
      workspaceId: clearWorkspaceId ? null : (workspaceId ?? this.workspaceId),
      instagramReviewing: instagramReviewing ?? this.instagramReviewing,
      dark: dark ?? this.dark,
      pendingPhone: clearPendingPhone ? null : (pendingPhone ?? this.pendingPhone),
      maskedPhone: clearMaskedPhone ? null : (maskedPhone ?? this.maskedPhone),
      otpExpiresIn: otpExpiresIn ?? this.otpExpiresIn,
      introSeen: introSeen ?? this.introSeen,
    );
  }

  @override
  String toString() => 'SessionState(gate: $gate, booting: $booting, dark: $dark)';
}
