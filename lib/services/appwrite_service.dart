import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;

  late Client client;
  late Account account;
  late Databases db;

  final String projectId = '68866a55002c3162f2fa';
  final String databaseId = '68866b21003441437542';
  final String collectionId = '68866b2d00325921842a';
  final String endpoint = 'https://cloud.appwrite.io/v1';

  AppwriteService._internal() {
    client = Client()
      ..setEndpoint(endpoint)
      ..setProject(projectId)
      ..setSelfSigned();

    account = Account(client);
    db = Databases(client);
  }

  Future<User?> createAccount(
      String email, String password, String name) async {
    try {
      await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      return login(email, password);
    } catch (e) {
      // ignore: avoid_print
      print("Error creating account: $e");
      return null;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      await account.createEmailSession(email: email, password: password);
      return getCurrentUser();
    } catch (e) {
      // ignore: avoid_print
      print("Login failed: $e");
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      return await account.get();
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSessions();
    } catch (e) {
      // ignore: avoid_print
      print("Logout failed: $e");
    }
  }

  Future<void> createUserDoc(String userId) async {
    try {
      await db.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'recent_apps': [],
          'last_updated': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );
    } catch (e) {
      // ignore: avoid_print
      print("Error creating user document: $e");
    }
  }

  Future<bool> hasUserDoc(String userId) async {
    try {
      final docs = await db.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [Query.equal('userId', userId)],
      );
      return docs.documents.isNotEmpty;
    } catch (e) {
      // ignore: avoid_print
      print("Error checking user doc: $e");
      return false;
    }
  }
}

extension on Account {
  Future<void> createEmailSession(
      {required String email, required String password}) async {}
}
