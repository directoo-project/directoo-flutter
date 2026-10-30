import '../../core/api_client.dart';
import '../../core/json.dart';
import '../../domain/entities/models.dart';
import 'api_paths.dart';

abstract class TicketsRemoteDataSource {
  Future<List<Ticket>> tickets(int id, {String? status, String? priority, String? search});
  Future<Ticket> ticket(int id, int ticketId);
  Future<Ticket> saveTicket(int id, Json data, {int? ticketId});
  Future<void> deleteTicket(int id, int ticketId);
  Future<void> addTicketComment(int id, int ticketId, String content);
}

class TicketsRemoteDataSourceImpl implements TicketsRemoteDataSource {
  TicketsRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<Ticket>> tickets(int id, {String? status, String? priority, String? search}) {
      final query = <String, String>{
        if (status != null && status.isNotEmpty && status != 'all') 'status': status,
        if (priority != null && priority.isNotEmpty && priority != 'all') 'priority': priority,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      return _client.get(
        Uri(path: workspacePath(id, 'tickets/'), queryParameters: query).toString(),
        auth: true,
        parse: (data) => [for (final item in asJsonList(data)) Ticket.fromJson(item)],
      );
    }

  @override
  Future<Ticket> ticket(int id, int ticketId) {
      return _client.get(workspacePath(id, 'tickets/$ticketId/'), auth: true, parse: (data) => Ticket.fromJson(asJson(data)));
    }

  @override
  Future<Ticket> saveTicket(int id, Json data, {int? ticketId}) {
      final path = ticketId == null ? workspacePath(id, 'tickets/') : workspacePath(id, 'tickets/$ticketId/');
      if (ticketId == null) {
        return _client.post(path, auth: true, data: data, parse: (body) => Ticket.fromJson(asJson(body)));
      }
      return _client.patch(path, auth: true, data: data, parse: (body) => Ticket.fromJson(asJson(body)));
    }

  @override
  Future<void> deleteTicket(int id, int ticketId) => _client.delete(workspacePath(id, 'tickets/$ticketId/'), auth: true);

  @override
  Future<void> addTicketComment(int id, int ticketId, String content) async {
      await _client.post(workspacePath(id, 'tickets/$ticketId/comments/'), auth: true, data: {'content': content});
    }
}
