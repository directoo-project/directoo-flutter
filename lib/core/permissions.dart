const roleRank = {
  'viewer': 1,
  'agent': 2,
  'manager': 3,
  'admin': 4,
  'owner': 5,
};

bool hasMinRole(String? role, String minimum) {
  if (role == null) return false;
  return (roleRank[role] ?? 0) >= (roleRank[minimum] ?? 0);
}

class WorkspacePermissions {
  const WorkspacePermissions(this.role);

  final String? role;

  bool get canReply => hasMinRole(role, 'agent');
  bool get canEditCustomers => hasMinRole(role, 'agent');
  bool get canDeleteCustomers => hasMinRole(role, 'manager');
  bool get canEditInvoices => hasMinRole(role, 'agent');
  bool get canDeleteInvoices => hasMinRole(role, 'manager');
  bool get canEditTickets => hasMinRole(role, 'agent');
  bool get canDeleteTickets => hasMinRole(role, 'manager');
  bool get canManageProducts => hasMinRole(role, 'manager');
  bool get canManageKnowledge => hasMinRole(role, 'manager');
  bool get canManageAutomation => hasMinRole(role, 'manager');
  bool get canManageTeam => hasMinRole(role, 'admin');
  bool get canManageInstagram => hasMinRole(role, 'admin');
  bool get canEditWorkspace => hasMinRole(role, 'admin');
  bool get canManageBilling => hasMinRole(role, 'owner');
}

List<String> assignableRoles(String? actorRole) {
  const all = ['viewer', 'agent', 'manager', 'admin'];
  if (actorRole == null) return const [];
  if (actorRole == 'owner') return all;
  final rank = roleRank[actorRole] ?? 0;
  return all.where((role) => (roleRank[role] ?? 0) < rank).toList();
}
