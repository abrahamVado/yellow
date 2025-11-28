import 'app_exception.dart';

class ErrorMapper {
  AppException map(Object error, StackTrace stackTrace) {
    // TODO: expand mapping from Dio, platform, etc.
    return AppException(error.toString(), error);
  }
}
