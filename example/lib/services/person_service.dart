import 'package:dart_serve/annotation/annotation.dart';
import 'package:example/models/person.dart';
import 'package:collection/collection.dart';

@Injectable()
class PersonService {
  var _idCounter = 1;
  final _people = <Person>[];

  void create(Person person) {
    _people.add(person.copyWith(id: '${_idCounter++}'));
  }

  List<Person> findAll() {
    return _people;
  }

  Person? findById(String id) {
    return _people.firstWhereOrNull((p) => p.id == id);
  }

  void deleteById(String id) {
    _people.removeWhere((p) => p.id == id);
  }
}
