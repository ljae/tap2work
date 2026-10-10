import 'operations_repository.dart';

abstract interface class CrewInvitationRepository {
  Future<OperationsResult> crewInvitation({
    required String actorId,
    required Json values,
  });
}
