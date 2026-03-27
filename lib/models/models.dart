import 'package:cloud_firestore/cloud_firestore.dart';

// ── User model ──
class AppUser {
  final String uid;
  final String email;
  String name;
  final String role; // teacher | student | parent
  final String linkedStudent; // student name or doc ID
  final String studentClass;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.linkedStudent = '',
    this.studentClass = '',
  });

  factory AppUser.fromFirestore(Map<String, dynamic> d, String uid) => AppUser(
    uid: uid,
    email: d['email'] ?? '',
    name: d['name'] ?? '',
    role: (d['role'] ?? 'student').toString().toLowerCase(),
    linkedStudent: d['linkedStudent'] ?? '',
    studentClass: d['class'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'email': email, 'name': name, 'role': role,
    'linkedStudent': linkedStudent, 'class': studentClass,
  };
}

// ── Lesson Log model ──
class LessonLog {
  final String id;
  final String studentName;
  final String date;
  final String subject;
  final String teacher;
  final String topic;
  final String progress;
  final String homework;
  final String observations;
  final String followUp;
  final String studentClass;
  final DateTime? createdAt;

  LessonLog({
    this.id = '',
    required this.studentName,
    required this.date,
    required this.subject,
    required this.teacher,
    required this.topic,
    required this.progress,
    this.homework = '',
    this.observations = '',
    this.followUp = '',
    this.studentClass = '',
    this.createdAt,
  });

  bool get isDone => ['completed', 'selesai', 'done', 'siap']
      .contains(progress.toLowerCase().trim());

  bool get isLate => observations.toLowerCase().contains('late') ||
      observations.toLowerCase().contains('lewat');

  bool get homeworkMissed => observations.toLowerCase().contains('not complet') ||
      observations.toLowerCase().contains('not submit');

  factory LessonLog.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LessonLog(
      id: doc.id,
      studentName:  d['studentName']  ?? '',
      date:         d['date']         ?? '',
      subject:      d['subject']      ?? '',
      teacher:      d['teacher']      ?? '',
      topic:        d['topic']        ?? '',
      progress:     d['progress']     ?? '',
      homework:     d['homework']     ?? '',
      observations: d['observations'] ?? '',
      followUp:     d['followUp']     ?? '',
      studentClass: d['class']        ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'studentName': studentName, 'date': date,
    'subject': subject,        'teacher': teacher,
    'topic': topic,            'progress': progress,
    'homework': homework,      'observations': observations,
    'followUp': followUp,      'class': studentClass,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

// ── Exam Result model ──
class ExamResult {
  final String id;
  final String studentName;
  final String term;
  final String subject;
  final String score;
  final String feedback;

  ExamResult({
    this.id = '',
    required this.studentName,
    required this.term,
    required this.subject,
    this.score = '',
    this.feedback = '',
  });

  factory ExamResult.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ExamResult(
      id: doc.id,
      studentName: d['studentName'] ?? '',
      term:        d['term']        ?? '',
      subject:     d['subject']     ?? '',
      score:       d['score']       ?? '',
      feedback:    d['feedback']    ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'studentName': studentName, 'term': term,
    'subject': subject, 'score': score, 'feedback': feedback,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
