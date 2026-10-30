import 'dart:async';

sealed class SessionEvent {
  SessionEvent() : completer = Completer<void>();

  final Completer<void> completer;

  @override
  String toString() => runtimeType.toString();
}

final class SessionBootstrapRequested extends SessionEvent {}

final class SessionIntroCompleted extends SessionEvent {}

final class SessionOtpRequested extends SessionEvent {
  SessionOtpRequested(this.phone);
  final String phone;
}

final class SessionOtpVerified extends SessionEvent {
  SessionOtpVerified(this.otp);
  final String otp;

  @override
  String toString() => 'SessionOtpVerified';
}

final class SessionProfileSkipped extends SessionEvent {}

final class SessionProfileCompleted extends SessionEvent {
  SessionProfileCompleted({required this.firstName, required this.lastName, required this.email});
  final String firstName;
  final String lastName;
  final String email;
}

final class SessionKnowledgeSkipped extends SessionEvent {}

final class SessionKnowledgeFinished extends SessionEvent {}

final class SessionInstagramPendingCleared extends SessionEvent {}

final class SessionInstagramSetupOpened extends SessionEvent {
  SessionInstagramSetupOpened({required this.reviewing});
  final bool reviewing;
}

final class SessionInstagramReviewingMarked extends SessionEvent {}

final class SessionWorkspaceSelected extends SessionEvent {
  SessionWorkspaceSelected(this.id);
  final int id;
}

final class SessionWorkspacesReloaded extends SessionEvent {}

final class SessionThemeToggled extends SessionEvent {}

final class SessionLogoutRequested extends SessionEvent {}

final class SessionUnauthorized extends SessionEvent {}

final class SessionGateRefreshRequested extends SessionEvent {}
