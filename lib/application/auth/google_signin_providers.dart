import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/google_signin_service.dart';

final googleSignInServiceProvider =
    Provider<GoogleSignInService>((ref) => GoogleSignInService());
