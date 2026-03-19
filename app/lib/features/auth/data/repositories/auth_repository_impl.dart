import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase Authentication implementation của [AuthRepository].
///
/// Sau khi đăng nhập thành công, thông tin user cơ bản (fullName, phone)
/// được lưu/lấy từ Firestore collection `users/{uid}`.
class FirebaseAuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  FirebaseAuthRepositoryImpl({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  // ─────────────────────────────── login ─────────────────────────

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Nếu không phải email (không chứa @), tra cứu username trên Firestore
      String loginEmail = email;
      if (!email.contains('@')) {
        final querySnapshot = await _db
            .collection('users')
            .where('username', isEqualTo: email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          return const Left(
              ServerFailure(message: 'Tên đăng nhập không tồn tại.'));
        }

        final userData = querySnapshot.docs.first.data();
        loginEmail = userData['email'] as String? ?? '';
        if (loginEmail.isEmpty) {
          return const Left(ServerFailure(
              message: 'Tài khoản này chưa có email liên kết.'));
        }
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );
      final user = await _userFromFirebase(credential.user!);
      return Right(user);
    } on fb.FirebaseAuthException catch (e) {
      return Left(ServerFailure(message: _authMessage(e.code)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─────────────────────────────── register ──────────────────────

  @override
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user!;
      await fbUser.updateDisplayName(fullName);

      // Lưu profile vào Firestore
      final username = email.split('@').first;
      await _db.collection('users').doc(fbUser.uid).set({
        'email': email,
        'username': username,
        'fullName': fullName,
        'phoneNumber': null,
        'employeeId': null,
        'department': null,
        'position': null,
        'workLocation': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final user = UserEntity(
        id: fbUser.uid,
        email: email,
        fullName: fullName,
        createdAt: DateTime.now(),
      );
      return Right(user);
    } on fb.FirebaseAuthException catch (e) {
      return Left(ServerFailure(message: _authMessage(e.code)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─────────────────────────────── logout ────────────────────────

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─────────────────────────────── getCurrentUser ────────────────

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) {
        return const Left(CacheFailure(message: 'Chưa đăng nhập'));
      }
      final user = await _userFromFirebase(fbUser);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─────────────────────────────── isLoggedIn ────────────────────

  @override
  Future<bool> isLoggedIn() async => _auth.currentUser != null;

  // ─────────────────────────────── helpers ───────────────────────

  Future<UserEntity> _userFromFirebase(fb.User fbUser) async {
    String fullName = fbUser.displayName ?? '';
    String? phoneNumber = fbUser.phoneNumber;
    String? employeeId;
    String? department;
    String? position;
    String? workLocation;
    String? shift;
    DateTime? createdAt;

    // Lấy thêm thông tin từ Firestore nếu có
    try {
      final doc = await _db.collection('users').doc(fbUser.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        fullName = (data['fullName'] as String?) ?? fullName;
        phoneNumber = (data['phoneNumber'] as String?) ?? phoneNumber;
        employeeId = data['employeeId'] as String?;
        department = data['department'] as String?;
        position = data['position'] as String?;
        workLocation = data['workLocation'] as String?;
        shift = data['shift'] as String?;
        final ts = data['createdAt'];
        if (ts is Timestamp) {
          createdAt = ts.toDate();
        }
      }
    } catch (_) {
      // Bỏ qua lỗi đọc Firestore, dùng data từ FirebaseAuth
    }

    return UserEntity(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      fullName: fullName,
      avatarUrl: fbUser.photoURL,
      phoneNumber: phoneNumber,
      employeeId: employeeId,
      department: department,
      position: position,
      workLocation: workLocation,
      shift: shift,
      createdAt: createdAt,
    );
  }

  String _authMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Tài khoản không tồn tại.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi mạng. Kiểm tra kết nối internet.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      default:
        return 'Đã xảy ra lỗi: $code';
    }
  }
}
