import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';

import '../models/chat_user.dart';
import '../models/message.dart';
import 'notification_access_token.dart';

class APIs {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;

  static ChatUser me = ChatUser(
      id: user.uid,
      name: user.displayName.toString(),
      email: user.email.toString(),
      about: "Hey, I'm using We Chat!",
      image: user.photoURL.toString(),
      createdAt: '',
      isOnline: false,
      lastActive: '',
      pushToken: '');

  static User get user => auth.currentUser!;
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  // ─── AUTH: Email/Senha ───────────────────────────────────────────────────

  static Future<UserCredential> loginWithEmail(
      String email, String password) async {
    return await auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  static Future<UserCredential> registerWithEmail(
      String name, String email, String password) async {
    final credential = await auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await credential.user!.updateDisplayName(name);
    return credential;
  }

  static Future<void> sendPasswordReset(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  // ─── AUTH: Google ────────────────────────────────────────────────────────

  static Future<UserCredential?> loginWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await auth.signInWithCredential(credential);
  }

  // ─── AUTH: Telefone ──────────────────────────────────────────────────────

  static Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Erro de verificação');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  static Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await auth.signInWithCredential(credential);
  }

  // ─── Firebase Messaging ──────────────────────────────────────────────────

  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();
    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('Push Token: $t');
      }
    });
  }

  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg) async {
    try {
      final body = {
        "message": {
          "token": chatUser.pushToken,
          "notification": {
            "title": me.name,
            "body": msg,
          },
        }
      };
      const projectID = 'we-chat-75f13';
      final bearerToken = await NotificationAccessToken.getToken;
      if (bearerToken == null) return;
      var res = await post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectID/messages:send'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $bearerToken'
        },
        body: jsonEncode(body),
      );
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }
  }

  // ─── User ────────────────────────────────────────────────────────────────

  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});
      return true;
    }
    return false;
  }

  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();
        APIs.updateActiveStatus(true);
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatUser = ChatUser(
        id: user.uid,
        name: user.displayName.toString(),
        email: user.email.toString(),
        about: "Hey, I'm using We Chat!",
        image: user.photoURL.toString(),
        createdAt: time,
        isOnline: false,
        lastActive: time,
        pushToken: '');
    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    return firestore
        .collection('users')
        .where('id', whereIn: userIds.isEmpty ? [''] : userIds)
        .snapshots();
  }

  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
  }

  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  static Future<void> updateProfilePicture(File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');
    await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));
    me.image = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'image': me.image});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  // ─── Chat ────────────────────────────────────────────────────────────────

  static String getConversationID(String id) =>
      user.uid.hashCode <= id.hashCode
          ? '${user.uid}_$id'
          : '${id}_${user.uid}';

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final Message message = Message(
        toId: chatUser.id,
        msg: msg,
        read: '',
        type: type,
        fromId: user.uid,
        sent: time);
    final ref = firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value) =>
        sendPushNotification(
            chatUser, type == Type.text ? msg : '🎵 Áudio'));
  }

  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromId)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child(
        'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  // ─── Áudio temporário ────────────────────────────────────────────────────

  static Future<void> sendChatAudio(ChatUser chatUser, File file) async {
    try {
      final time = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = storage.ref().child(
          'audios/${getConversationID(chatUser.id)}/$time.aac');
      await ref.putFile(file, SettableMetadata(contentType: 'audio/aac'));
      final audioUrl = await ref.getDownloadURL();
      await sendMessage(chatUser, audioUrl, Type.audio);
      log('Audio sent: $audioUrl');
    } catch (e) {
      log('sendChatAudioE: $e');
    }
  }

  // Marca áudio como reproduzido e agenda deleção em 5 segundos
  static Future<void> markAudioPlayed(Message message) async {
    try {
      // Atualiza isPlayed no Firestore
      await firestore
          .collection('chats/${getConversationID(message.fromId)}/messages/')
          .doc(message.sent)
          .update({'isPlayed': true});

      // Aguarda 5 segundos e deleta
      await Future.delayed(const Duration(seconds: 5));
      await deleteAudioMessage(message);
    } catch (e) {
      log('markAudioPlayedE: $e');
    }
  }

  // Deleta mensagem de áudio do Firestore e Storage
  static Future<void> deleteAudioMessage(Message message) async {
    try {
      // Deleta do Firestore
      await firestore
          .collection('chats/${getConversationID(message.toId)}/messages/')
          .doc(message.sent)
          .delete();

      // Deleta do Storage
      await storage.refFromURL(message.msg).delete();
      log('Audio deleted: ${message.sent}');
    } catch (e) {
      log('deleteAudioMessageE: $e');
    }
  }

  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .delete();
    if (message.type == Type.image || message.type == Type.audio) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }
}
