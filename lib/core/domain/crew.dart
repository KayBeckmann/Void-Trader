enum CrewRole { worker, researcher, pilot, guard }

class CrewMember {
  final String id;
  final String name;
  final CrewRole role;
  final double dailyWage; // Credits/Tag
  String? assignedBuildingId;

  CrewMember({
    required this.id,
    required this.name,
    required this.role,
    required this.dailyWage,
    this.assignedBuildingId,
  });

  bool get isAssigned => assignedBuildingId != null;

  String get roleLabel => switch (role) {
        CrewRole.worker => 'Arbeiter',
        CrewRole.researcher => 'Forscher',
        CrewRole.pilot => 'Pilot',
        CrewRole.guard => 'Wache',
      };

  static CrewMember hire(CrewRole role, int index) {
    final names = [
      'Alia', 'Brex', 'Cova', 'Drex', 'Elan',
      'Fyra', 'Galt', 'Hira', 'Ivar', 'Juno',
    ];
    final wages = {
      CrewRole.worker: 80.0,
      CrewRole.researcher: 200.0,
      CrewRole.pilot: 150.0,
      CrewRole.guard: 120.0,
    };
    return CrewMember(
      id: '${role.name}_$index',
      name: '${names[index % names.length]} ${role.name[0].toUpperCase()}.',
      role: role,
      dailyWage: wages[role]!,
    );
  }
}
