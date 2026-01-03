import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/login_service.dart';

final loginServiceProvider = Provider((ref) => LoginService());
