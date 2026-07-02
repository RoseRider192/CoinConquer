class WorkSession {
  final int? id;
  final int jobId;
  final double hoursWorked;
  final double hourlyRate;
  final double totalIncome;
  final String date; // YYYY-MM-DD
  final String? note;

  const WorkSession({
    this.id,
    required this.jobId,
    required this.hoursWorked,
    required this.hourlyRate,
    required this.totalIncome,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'job_id': jobId,
      'hours_worked': hoursWorked,
      'hourly_rate': hourlyRate,
      'total_income': totalIncome,
      'date': date,
      'note': note,
    };
  }

  factory WorkSession.fromMap(Map<String, dynamic> map) {
    return WorkSession(
      id: map['id'] as int?,
      jobId: map['job_id'] as int,
      hoursWorked: (map['hours_worked'] as num).toDouble(),
      hourlyRate: (map['hourly_rate'] as num).toDouble(),
      totalIncome: (map['total_income'] as num).toDouble(),
      date: map['date'] as String,
      note: map['note'] as String?,
    );
  }
}
