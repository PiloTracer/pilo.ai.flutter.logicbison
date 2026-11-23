import 'user.dart';

abstract interface class UserRepository {
  Future<User> currentUser();
}
