import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db   = FirebaseFirestore.instance;

  // Collections
  static CollectionReference get _users  => _db.collection('users');
  static CollectionReference get _logs   => _db.collection('lessonLogs');
  static CollectionReference get _exams  => _db.collection('examResults');

  // ── AUTH ──
  static Future<AppUser?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(), password: password.trim());
    final uid = cred.user!.uid;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc.data() as Map<String, dynamic>, uid);
  }

  static Future<void> logout() => _auth.signOut();

  static Future<AppUser?> currentUserProfile() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final doc = await _users.doc(u.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc.data() as Map<String, dynamic>, u.uid);
  }

  // ── USERS ──
  static Future<List<AppUser>> getStudents() async {
    final snap = await _users.where('role', isEqualTo: 'student').get();
    return snap.docs.map((d) =>
      AppUser.fromFirestore(d.data() as Map<String, dynamic>, d.id)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static Future<void> updateProfile({required String uid, required String name, String? newPassword}) async {
    await _users.doc(uid).update({'name': name});
    if (newPassword != null && newPassword.isNotEmpty) {
      await _auth.currentUser?.updatePassword(newPassword);
    }
  }

  static Future<void> addUser(AppUser user, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: user.email, password: password);
    await _users.doc(cred.user!.uid).set(user.toMap());
  }

  // ── LESSON LOGS ──
  static Stream<List<LessonLog>> logsStream({String? studentName, String? subject}) {
    Query q = _logs;
    if (studentName != null && studentName.isNotEmpty) {
      q = q.where('studentName', isEqualTo: studentName);
    }
    if (subject != null && subject.isNotEmpty) {
      q = q.where('subject', isEqualTo: subject);
    }
    return q.snapshots().map((s) {
      final list = s.docs.map((d) => LessonLog.fromFirestore(d)).toList();
      list.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      return list;
    });
  }

  static Future<List<LessonLog>> getLogs({String? studentName, String? subject}) async {
    Query q = _logs;
    if (studentName != null && studentName.isNotEmpty) {
      q = q.where('studentName', isEqualTo: studentName);
    }
    if (subject != null && subject.isNotEmpty) {
      q = q.where('subject', isEqualTo: subject);
    }
    final snap = await q.get();
    final list = snap.docs.map((d) => LessonLog.fromFirestore(d)).toList();
    list.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    return list;
  }

  static Future<String> addLog(LessonLog log) async {
    final ref = await _logs.add(log.toMap());
    return ref.id;
  }

  static Future<void> updateLog(String id, Map<String, dynamic> data) =>
    _logs.doc(id).update(data);

  static Future<void> deleteLog(String id) => _logs.doc(id).delete();

  // Get all unique student names from logs
  static Future<List<String>> getStudentNames() async {
    final snap = await _logs.get();
    final names = snap.docs
      .map((d) => (d.data() as Map)['studentName']?.toString() ?? '')
      .where((n) => n.isNotEmpty)
      .toSet()
      .toList()..sort();
    return names;
  }

  // ── EXAM RESULTS ──
  static Future<List<ExamResult>> getExams({String? studentName}) async {
    Query q = _exams;
    if (studentName != null && studentName.isNotEmpty) {
      q = q.where('studentName', isEqualTo: studentName);
    }
    final snap = await q.get();
    final list = snap.docs.map((d) => ExamResult.fromFirestore(d)).toList();
    list.sort((a, b) => a.term.compareTo(b.term));
    return list;
  }

  static Future<void> addExam(ExamResult exam) => _exams.add(exam.toMap());

  // ── STATS (for dashboard) ──
  static Future<Map<String, dynamic>> getDashboardStats(String? studentName) async {
    final logs = await getLogs(studentName: studentName);
    final done  = logs.where((l) => l.isDone).length;
    final late  = logs.where((l) => l.isLate).length;
    final hwMiss= logs.where((l) => l.homeworkMissed).length;
    final subjects = logs.map((l) => l.subject).toSet().toList();

    return {
      'total':    logs.length,
      'done':     done,
      'late':     late,
      'hwMissed': hwMiss,
      'subjects': subjects,
      'logs':     logs,
    };
  }
}
