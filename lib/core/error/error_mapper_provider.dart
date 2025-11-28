import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_mapper.dart';

final errorMapperProvider = Provider<ErrorMapper>((ref) {
  return ErrorMapper();
});
