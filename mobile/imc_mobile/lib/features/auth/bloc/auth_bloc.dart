import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/security/secure_enclave_storage.dart';
import '../../../services/imc_api_service.dart';
import '../../../models/agent.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.agentId,
    required this.pin,
  });

  final String agentId;
  final String pin;

  @override
  List<Object?> get props => [agentId, pin];
}

class AuthDuressPinEntered extends AuthEvent {
  const AuthDuressPinEntered({
    required this.agentId,
    required this.pin,
  });

  final String agentId;
  final String pin;

  @override
  List<Object?> get props => [agentId, pin];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthAbortMission extends AuthEvent {
  const AuthAbortMission();
}

class AuthSessionChecked extends AuthEvent {
  const AuthSessionChecked();
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthVerifyingCertificate extends AuthState {
  const AuthVerifyingCertificate();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.agent});

  final Agent agent;

  @override
  List<Object?> get props => [agent];
}

class AuthDuressMode extends AuthState {
  const AuthDuressMode({required this.agent});

  final Agent agent;

  @override
  List<Object?> get props => [agent];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthFailure extends AuthState {
  const AuthFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthAborted extends AuthState {
  const AuthAborted();
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<AuthSessionChecked>(_onSessionChecked);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthDuressPinEntered>(_onDuressPinEntered);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthAbortMission>(_onAbortMission);
  }

  final SecureEnclaveStorage _storage = SecureEnclaveStorage.instance;
  final IMCApiService _api = IMCApiService.instance;

  Future<void> _onSessionChecked(
    AuthSessionChecked event,
    Emitter<AuthState> emit,
  ) async {
    final hasSession = await _storage.hasValidSession();
    if (hasSession) {
      final agentId = await _storage.getAgentId() ?? 'UNKNOWN';
      emit(AuthAuthenticated(
        agent: Agent.mock.copyWith(id: agentId),
      ));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.agentId.trim().isEmpty || event.pin.length != 6) {
      emit(const AuthFailure(message: 'AUTHENTICATION FAILED — INVALID CREDENTIALS'));
      return;
    }

    emit(const AuthVerifyingCertificate());

    try {
      final duressPin = await _storage.getDuressPin();
      if (duressPin == event.pin) {
        await _activateDuressMode(event.agentId, emit);
        return;
      }

      final agent = await _api.login(
        event.agentId.toUpperCase(),
        event.pin,
      );

      if (agent == null) {
        emit(const AuthFailure(message: 'AUTHENTICATION FAILED — INVALID CREDENTIALS'));
        return;
      }

      await _storage.saveAgentId(agent.id);
      await _storage.saveClassificationLevel(
        agent.classificationLevel.name.toLowerCase(),
      );

      emit(AuthAuthenticated(agent: agent));
    } catch (_) {
      emit(const AuthFailure(message: 'AUTHENTICATION FAILED — NETWORK ERROR'));
    }
  }

  Future<void> _onDuressPinEntered(
    AuthDuressPinEntered event,
    Emitter<AuthState> emit,
  ) async {
    await _activateDuressMode(event.agentId, emit);
  }

  Future<void> _activateDuressMode(String agentId, Emitter<AuthState> emit) async {
    try {
      await _api.sendDuressAlert(
        agentId: agentId,
        fakeDashboard: 'PERSONAL_NOTES',
      );
    } catch (_) {}

    emit(AuthDuressMode(
      agent: Agent.mock.copyWith(id: agentId, status: AgentStatus.underDuress),
    ));
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _storage.wipeAll();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onAbortMission(
    AuthAbortMission event,
    Emitter<AuthState> emit,
  ) async {
    await _storage.wipeAll();
    emit(const AuthAborted());
  }
}

extension AgentCopyWith on Agent {
  Agent copyWith({
    String? id,
    String? callSign,
    AgentStatus? status,
    ClassificationLevel? classificationLevel,
    List<String>? assignedCaseIds,
    String? avatarUrl,
  }) {
    return Agent(
      id: id ?? this.id,
      callSign: callSign ?? this.callSign,
      status: status ?? this.status,
      classificationLevel: classificationLevel ?? this.classificationLevel,
      assignedCaseIds: assignedCaseIds ?? this.assignedCaseIds,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
