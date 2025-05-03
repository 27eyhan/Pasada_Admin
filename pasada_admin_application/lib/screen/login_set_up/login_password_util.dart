import 'package:bcrypt/bcrypt.dart';

class LoginPasswordUtil {
  bool checkPassword(String password, String hashedPassword) {
    return BCrypt.checkpw(password, hashedPassword);
  }
}