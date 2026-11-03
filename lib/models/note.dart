class Note {
  final int? id;
  final String? cloudId;

  final String uid;
  final String title;
  final String content;
  final String date;

  Note({
    this.id,
    this.cloudId,
    required this.uid,
    required this.title,
    required this.content,
    required this.date,
  });

  // Dados utilizados pelo SQLite
  Map<String, dynamic> toMap() => {
    'id': id,
    'cloudId': cloudId,
    'uid': uid,
    'title': title,
    'content': content,
    'date': date,
  };

  // Dados utilizados pelo Firestore
  Map<String, dynamic> toFirestore() {
    return {'uid': uid, 'title': title, 'content': content, 'date': date};
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      cloudId: map['cloudId'] as String?,
      uid: map['uid'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      date: map['date'] as String,
    );
  }

  factory Note.fromFirestore(Map<String, dynamic> map, String documentId) {
    return Note(
      cloudId: documentId,
      uid: map['uid'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      date: map['date'] as String,
    );
  }
}
