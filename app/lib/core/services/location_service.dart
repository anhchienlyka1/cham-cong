import 'package:geolocator/geolocator.dart';
import '../../config/constants/app_constants.dart';

/// Cung cấp quyền & lấy vị trí hiện tại, kiểm tra trong vùng văn phòng.
class LocationService {
  /// Yêu cầu quyền location (hỏi lần đầu, runtime).
  /// Trả về true nếu được cấp đủ quyền.
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Lấy vị trí hiện tại. Trả về null nếu không đủ quyền hoặc lỗi.
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Kiểm tra xem vị trí hiện tại có trong vùng văn phòng không.
  Future<bool> isAtOffice() async {
    final pos = await getCurrentPosition();
    if (pos == null) return false;
    final dist = Geolocator.distanceBetween(
      AppConstants.officeLatitude,
      AppConstants.officeLongitude,
      pos.latitude,
      pos.longitude,
    );
    return dist <= AppConstants.officeRadiusMeters;
  }
}
