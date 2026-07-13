import '../core/network/dio_client.dart';

class CallSessionDto {
  const CallSessionDto({
    required this.id,
    required this.conversationId,
    required this.callType,
    required this.status,
    required this.callerId,
    required this.calleeId,
    this.iceServers = const [],
  });

  final String id;
  final String conversationId;
  final String callType;
  final String status;
  final int callerId;
  final int calleeId;
  final List<Map<String, dynamic>> iceServers;

  factory CallSessionDto.fromJson(Map<String, dynamic> json) {
    final servers = json['ice_servers'];
    return CallSessionDto(
      id: '${json['id']}',
      conversationId: '${json['conversation_id']}',
      callType: '${json['call_type']}',
      status: '${json['status']}',
      callerId: json['caller_id'] as int? ?? 0,
      calleeId: json['callee_id'] as int? ?? 0,
      iceServers: servers is List
          ? servers.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : const [],
    );
  }
}

class CallRepository {
  CallRepository(this._client);

  final DioClient _client;

  Future<List<Map<String, dynamic>>> getIceServers() async {
    final response = await _client.get<Map<String, dynamic>>('/calls/ice-servers/');
    final servers = response.data?['ice_servers'];
    if (servers is List) {
      return servers.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  Future<CallSessionDto> initiateCall({
    required String conversationId,
    required String callType,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/calls/',
      data: {
        'conversation_id': conversationId,
        'call_type': callType,
      },
    );
    return CallSessionDto.fromJson(response.data!);
  }

  Future<CallSessionDto> acceptCall(String callId) async {
    final response = await _client.post<Map<String, dynamic>>('/calls/$callId/accept/');
    return CallSessionDto.fromJson(response.data!);
  }

  Future<CallSessionDto> rejectCall(String callId) async {
    final response = await _client.post<Map<String, dynamic>>('/calls/$callId/reject/');
    return CallSessionDto.fromJson(response.data!);
  }

  Future<CallSessionDto> cancelCall(String callId) async {
    final response = await _client.post<Map<String, dynamic>>('/calls/$callId/cancel/');
    return CallSessionDto.fromJson(response.data!);
  }

  Future<CallSessionDto> hangupCall(String callId) async {
    final response = await _client.post<Map<String, dynamic>>('/calls/$callId/hangup/');
    return CallSessionDto.fromJson(response.data!);
  }

  Future<String> getCallWsTicket(String conversationId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/calls/conversations/$conversationId/ws-ticket/',
    );
    return '${response.data?['ticket']}';
  }
}
