import '../mock_data/users/mock_users.dart';
import '../models/app_user.dart';

class UserRepository {
  const UserRepository();

  AppUser getCurrentUser() {
    return touristUser;
  }
}
