import '../../core/json.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/tickets_repository.dart';
import '../datasources/tickets_remote_data_source.dart';

class TicketsRepositoryImpl implements TicketsRepository {
  TicketsRepositoryImpl(this._remote);

  final TicketsRemoteDataSource _remote;

  @override
  Future<List<Ticket>> tickets(int id, {String? status, String? priority, String? search}) => _remote.tickets(id, status: status, priority: priority, search: search);

  @override
  Future<Ticket> ticket(int id, int ticketId) => _remote.ticket(id, ticketId);

  @override
  Future<Ticket> saveTicket(int id, Json data, {int? ticketId}) => _remote.saveTicket(id, data, ticketId: ticketId);

  @override
  Future<void> deleteTicket(int id, int ticketId) => _remote.deleteTicket(id, ticketId);

  @override
  Future<void> addTicketComment(int id, int ticketId, String content) => _remote.addTicketComment(id, ticketId, content);
}
