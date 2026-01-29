---
name: firebase-flutter
description: Firebase integration patterns for Flutter including Authentication, Cloud Firestore, and Storage. Use this skill when working with Firebase services, database queries, or authentication flows.
---

# Firebase Flutter Integration Skill

## Firebase Authentication

### Email/Password Sign Up
```dart
Future<UserCredential?> signUp(String email, String password) async {
  try {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential;
  } on FirebaseAuthException catch (e) {
    // Handle specific error codes
    switch (e.code) {
      case 'weak-password':
        throw 'Şifre çok zayıf';
      case 'email-already-in-use':
        throw 'Bu e-posta zaten kullanımda';
      default:
        throw 'Kayıt hatası: ${e.message}';
    }
  }
}
```

### Email/Password Sign In
```dart
Future<UserCredential?> signIn(String email, String password) async {
  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential;
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'user-not-found':
        throw 'Kullanıcı bulunamadı';
      case 'wrong-password':
        throw 'Yanlış şifre';
      default:
        throw 'Giriş hatası: ${e.message}';
    }
  }
}
```

### Current User
```dart
// Get current user
final user = FirebaseAuth.instance.currentUser;

// Listen to auth state
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  if (user == null) {
    // User is signed out
  } else {
    // User is signed in
  }
});
```

### Sign Out
```dart
await FirebaseAuth.instance.signOut();
```

## Cloud Firestore

### Document Operations

#### Create/Set Document
```dart
// With auto-generated ID
final docRef = await FirebaseFirestore.instance
    .collection('users')
    .add({'name': 'John', 'email': 'john@example.com'});

// With specific ID
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .set({'name': 'John', 'email': 'john@example.com'});

// Merge with existing
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .set({'name': 'John'}, SetOptions(merge: true));
```

#### Read Document
```dart
// Single read
final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

if (doc.exists) {
  final data = doc.data()!;
  return UserModel.fromMap(data, doc.id);
}
```

#### Update Document
```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
      'name': 'New Name',
      'updatedAt': FieldValue.serverTimestamp(),
    });
```

#### Delete Document
```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .delete();
```

### Collection Queries

#### Basic Query
```dart
final snapshot = await FirebaseFirestore.instance
    .collection('meetups')
    .where('type', isEqualTo: 'football')
    .orderBy('date', descending: true)
    .limit(20)
    .get();

final meetups = snapshot.docs
    .map((doc) => MeetupModel.fromMap(doc.data(), doc.id))
    .toList();
```

#### Stream Query (Real-time)
```dart
Stream<List<MeetupModel>> getMeetupsStream() {
  return FirebaseFirestore.instance
      .collection('meetups')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => MeetupModel.fromMap(doc.data(), doc.id))
          .toList());
}
```

#### Compound Queries
```dart
// Multiple conditions
final snapshot = await FirebaseFirestore.instance
    .collection('meetups')
    .where('type', isEqualTo: 'football')
    .where('date', isGreaterThan: DateTime.now())
    .where('isFull', isEqualTo: false)
    .get();

// Array contains
final snapshot = await FirebaseFirestore.instance
    .collection('meetups')
    .where('participantIds', arrayContains: userId)
    .get();
```

### Subcollections

```dart
// Add to subcollection
await FirebaseFirestore.instance
    .collection('chats')
    .doc(chatId)
    .collection('messages')
    .add({
      'text': message,
      'senderId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

// Query subcollection
final messages = FirebaseFirestore.instance
    .collection('chats')
    .doc(chatId)
    .collection('messages')
    .orderBy('timestamp', descending: true)
    .snapshots();
```

### Transactions

```dart
await FirebaseFirestore.instance.runTransaction((transaction) async {
  final meetupRef = FirebaseFirestore.instance
      .collection('meetups')
      .doc(meetupId);

  final snapshot = await transaction.get(meetupRef);
  final currentCount = snapshot.data()!['currentParticipants'] as int;
  final maxCount = snapshot.data()!['maxParticipants'] as int;

  if (currentCount >= maxCount) {
    throw 'Meetup is full';
  }

  transaction.update(meetupRef, {
    'currentParticipants': currentCount + 1,
    'participantIds': FieldValue.arrayUnion([userId]),
  });
});
```

### Batch Writes

```dart
final batch = FirebaseFirestore.instance.batch();

batch.set(doc1Ref, data1);
batch.update(doc2Ref, data2);
batch.delete(doc3Ref);

await batch.commit();
```

## Firebase Storage

### Upload File
```dart
Future<String> uploadImage(File file, String path) async {
  final ref = FirebaseStorage.instance.ref().child(path);
  final uploadTask = ref.putFile(file);

  final snapshot = await uploadTask.whenComplete(() {});
  final downloadUrl = await snapshot.ref.getDownloadURL();

  return downloadUrl;
}
```

### Upload with Progress
```dart
final uploadTask = ref.putFile(file);

uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
  final progress = snapshot.bytesTransferred / snapshot.totalBytes;
  print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
});

await uploadTask.whenComplete(() {});
```

### Delete File
```dart
await FirebaseStorage.instance.ref().child(path).delete();
```

## Model Pattern

### FromMap / ToMap
```dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt,
    );
  }
}
```

## Security Rules Reference

### Firestore Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // Meetups readable by all authenticated users
    match /meetups/{meetupId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.organizerId;
    }
  }
}
```

## Guidelines

- Always handle FirebaseException with user-friendly messages
- Use transactions for operations that need atomicity
- Use FieldValue.serverTimestamp() for consistent timestamps
- Create indexes for compound queries in Firebase Console
- Use streams for real-time data, futures for one-time reads
- Store only necessary data - avoid deeply nested documents
- Use subcollections for large or frequently accessed related data
