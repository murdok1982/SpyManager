import 'package:bloc/bloc.dart';
import 'dead_man_switch_event.dart';
import 'dead_man_switch_state.dart';
import '../../core/storage/secure_enclave_storage.dart';
import '../../services/offline_sync_service.dart';

/// BLoC for Dead Man's Switch functionality
class DeadManSwitchBloc extends Bloc<DeadManSwitchEvent, DeadManSwitchState> {
  DeadManSwitchBloc() : super(DeadManSwitchInitial()) {
    on<UpdateCheckInInterval>((event, emit) async {
      await SecureEnclaveStorage().write(
        key: 'check_in_interval',
        value: event.intervalMinutes.toString(),
      );
      emit(DeadManSwitchUpdated(intervalMinutes: event.intervalMinutes));
    });

    on<CheckIn>((event, emit) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await SecureEnclaveStorage().write(
        key: 'last_check_in',
        value: now.toString(),
      );
      emit(DeadManSwitchCheckedIn(lastCheckIn: now));
    });

    on<TriggerDeadManSwitch>((event, emit) async {
      emit(DeadManSwitchTriggered());
      // Wipe storage and notify backend
      await SecureEnclaveStorage.wipeAll();
      try {
        await ApiClient().dio.post('/api/dead-man/triggered');
      } catch (_) {
        await OfflineSyncService().saveUnsynced({
          'type': 'dead_man_triggered',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      exit(0);
    });
  }
}
