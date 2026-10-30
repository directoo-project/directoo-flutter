import '../../core/json.dart';
import '../entities/models.dart';

abstract class TicketsRepository {
  Future<List<Ticket>> tickets(int id, {String? status, String? priority, String? search});
  Future<Ticket> ticket(int id, int ticketId);
  Future<Ticket> saveTicket(int id, Json data, {int? ticketId});
  Future<void> deleteTicket(int id, int ticketId);
  Future<void> addTicketComment(int id, int ticketId, String content);
}
