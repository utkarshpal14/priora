enum ReminderSound {
  chime(
    id: 'priora_chime',
    name: 'Priora Chime',
    description: 'Harmonic 5s chime (Default)',
    icon: '✨',
    resourceName: 'priora_chime',
  ),
  alert(
    id: 'priora_alert',
    name: 'Priora Alert',
    description: 'Dynamic resonant 5s alert',
    icon: '🚨',
    resourceName: 'priora_alert',
  ),
  crystalBell(
    id: 'priora_bell',
    name: 'Crystal Bell',
    description: 'Crisp & resonant bell chime',
    icon: '🔔',
    resourceName: 'priora_bell',
  ),
  gentleMarimba(
    id: 'priora_marimba',
    name: 'Gentle Marimba',
    description: 'Warm acoustic woodblock melody',
    icon: '🪵',
    resourceName: 'priora_marimba',
  ),
  digitalPulse(
    id: 'priora_pulse',
    name: 'Digital Pulse',
    description: 'Futuristic high-tech sweep pulse',
    icon: '⚡',
    resourceName: 'priora_pulse',
  ),
  calmHarp(
    id: 'priora_harp',
    name: 'Calm Harp',
    description: 'Soothing ambient glissando',
    icon: '🪕',
    resourceName: 'priora_harp',
  ),
  systemDefault(
    id: 'default',
    name: 'System Default',
    description: 'Native OS notification sound',
    icon: '📱',
    resourceName: null,
  );

  final String id;
  final String name;
  final String description;
  final String icon;
  final String? resourceName;

  const ReminderSound({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.resourceName,
  });

  static ReminderSound fromId(String? id) {
    if (id == null || id.isEmpty) return ReminderSound.chime;
    return ReminderSound.values.firstWhere(
      (s) => s.id == id || s.resourceName == id,
      orElse: () => ReminderSound.chime,
    );
  }
}
