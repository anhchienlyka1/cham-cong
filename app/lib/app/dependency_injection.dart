import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../features/attendance/domain/repositories/attendance_repository.dart';
import '../features/attendance/domain/usecases/check_in_usecase.dart';
import '../features/attendance/domain/usecases/check_out_usecase.dart';
import '../features/attendance/domain/usecases/get_attendance_history_usecase.dart';
import '../features/attendance/domain/usecases/get_today_record_usecase.dart';
import '../features/attendance/domain/usecases/delete_attendance_usecase.dart';
import '../features/attendance/domain/usecases/update_attendance_time_usecase.dart';
import '../features/attendance/presentation/bloc/attendance_bloc.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // ── Firebase services ────────────────────────────────────────────
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // ── Auth ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepositoryImpl(
      auth: sl<FirebaseAuth>(),
      db: sl<FirebaseFirestore>(),
    ),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl<AuthRepository>()));

  sl.registerLazySingleton(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
    ),
  );

  // ── Attendance ───────────────────────────────────────────────────
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(db: sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton(() => CheckInUseCase(sl<AttendanceRepository>()));
  sl.registerLazySingleton(() => CheckOutUseCase(sl<AttendanceRepository>()));
  sl.registerLazySingleton(
      () => GetAttendanceHistoryUseCase(sl<AttendanceRepository>()));
  sl.registerLazySingleton(
      () => GetTodayRecordUseCase(sl<AttendanceRepository>()));
  sl.registerLazySingleton(
      () => UpdateAttendanceTimeUseCase(sl<AttendanceRepository>()));
  sl.registerLazySingleton(
      () => DeleteAttendanceUseCase(sl<AttendanceRepository>()));

  sl.registerFactory(
    () => AttendanceBloc(
      checkInUseCase: sl<CheckInUseCase>(),
      checkOutUseCase: sl<CheckOutUseCase>(),
      getHistoryUseCase: sl<GetAttendanceHistoryUseCase>(),
      getTodayRecordUseCase: sl<GetTodayRecordUseCase>(),
      updateTimeUseCase: sl<UpdateAttendanceTimeUseCase>(),
      deleteUseCase: sl<DeleteAttendanceUseCase>(),
      authBloc: sl<AuthBloc>(),
    ),
  );
}
