class Person {
  final String? id;
  final String name;
  final int age;

  const Person({
    required this.name,
    required this.age,
    this.id,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      name: json['name'],
      age: json['age'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
      };

  Person copyWith({String? id}) {
    return Person(
      id: id,
      name: name,
      age: age,
    );
  }
}
