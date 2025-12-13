import 'package:dio/dio.dart';
import 'app_exception.dart';

class ErrorMapper {
  AppException map(Object error, StackTrace stackTrace) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AppException("Tiempo de espera agotado. Revisa tu conexión.", error);
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 400) {
            return AppException("Datos incorrectos. Verifica la información.", error);
          } else if (statusCode == 401) {
             return AppException("Código inválido o sesión expirada.", error);
          } else if (statusCode == 403) {
             return AppException("No tienes permiso para realizar esta acción.", error);
          } else if (statusCode == 404) {
             return AppException("No encontrado. Intenta nuevamente.", error);
          } else if (statusCode == 500) {
             return AppException("Error del servidor. Intenta más tarde.", error);
          }
          return AppException("Error de conexión: $statusCode", error);
        case DioExceptionType.connectionError:
          return AppException("Sin conexión a internet.", error);
        default:
          return AppException("Ha ocurrido un error inesperado.", error);
      }
    }
    return AppException("Error desconocido: ${error.toString()}", error);
  }
}
