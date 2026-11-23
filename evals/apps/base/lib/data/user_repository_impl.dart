import '../domain/user.dart';
import '../domain/user_repository.dart';

const _defaultUser = User(displayName: 'Ada Lovelace');

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl({this.user = _defaultUser});

  final User user;

  @override
  Future<User> currentUser() async => user;
}
