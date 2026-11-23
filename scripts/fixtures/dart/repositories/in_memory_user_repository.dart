// Fixture: an implementation importing the interface it `implements` is correct
// even when the file is not named `<interface>_impl.dart`. Must produce ZERO
// repository findings — this exact layout (in_memory_ / fake_ / remote_ prefixes)
// is common, and a false positive here gets the whole check switched off.

import '../domain/user.dart';
import '../domain/user_repository.dart';

class InMemoryUserRepository implements UserRepository {
  const InMemoryUserRepository(this._user);

  final User _user;
}
