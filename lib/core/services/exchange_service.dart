import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pin/core/services/chat_service.dart';
import 'package:pin/features/chat/presentation/screens/chats/model/Chat.dart';
import 'package:pin/features/exchanges/models/Exchange.dart';

class ExchangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  Future<String> createExchange({
    required String senderId,
    required String receiverId,
    required List<String> itemsOffered,
    required List<String> itemsRequested,
  }) async {
    try {
      DocumentReference exchangeRef =
          await _firestore.collection('exchanges').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'itemsOffered': itemsOffered,
        'itemsRequested': itemsRequested,
        'status': 'pendiente',
        'timestamp': FieldValue.serverTimestamp(),
        'lastModified': FieldValue.serverTimestamp(),
        'points': 100,
      });

      return "Intercambio creado con éxito: ${exchangeRef.id}";
    } catch (e) {
      print('Error al crear el intercambio: $e');
      return "Error al crear el intercambio";
    }
  }

  Future<String> cancelExchange(String exchangeId) async {
    try {
      await _firestore.collection('exchanges').doc(exchangeId).update({
        'status': 'cancelado',
        'lastModified': FieldValue.serverTimestamp(),
      });

      return "Intercambio cancelado con éxito";
    } catch (e) {
      print('Error al cancelar el intercambio: $e');
      return "Error al cancelar el intercambio";
    }
  }

  Future<Exchange?> getExchangeById(String exchangeId) async {
    try {
      DocumentSnapshot docSnapshot =
          await _firestore.collection('exchanges').doc(exchangeId).get();

      if (docSnapshot.exists) {
        return Exchange.fromFirestore(
            docSnapshot); // Retorna el objeto Exchange
      } else {
        print('El intercambio con el ID $exchangeId no existe');
        return null;
      }
    } catch (e) {
      print('Error al obtener el intercambio con ID $exchangeId: $e');
      rethrow;
    }
  }

  Future<void> updateUserPoints(String userId, int points) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        int currentPoints = userSnapshot['points'] ?? 0;
        transaction.update(userRef, {'points': currentPoints + points});
      });
    } catch (e) {
      print('Error al actualizar los puntos del usuario: $e');
      rethrow;
    }
  }

  Future<void> notifyNewExchange(String targetUserId) async {
    try {
      final String? currentUserId = await _chatService.getUserId();
      if (currentUserId == null) return;

      // Verifica si ya existe un chat con el usuario objetivo
      final chatId = await getOrCreateChat(currentUserId, targetUserId);

      // Envía el mensaje de notificación de intercambio en el chat correspondiente
      await sendExchangeNotification(chatId: chatId, senderId: currentUserId);
    } catch (e) {
      print('Error al notificar nuevo intercambio: $e');
    }
  }

  Future<void> sendExchangeNotification({
    required String chatId,
    required String senderId,
  }) async {
    try {
      final messageId = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc()
          .id; // Generar un ID único para el mensaje
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'content': '¡Tienes un nuevo intercambio!',
        'id': messageId,
        'sender': senderId,
        'status': 'viewed', // Estado del mensaje
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'exchangeNotification',
      });
    } catch (e) {
      print('Error al enviar la notificación de intercambio: $e');
    }
  }

  Future<String> getOrCreateChat(
      String currentUserId, String targetUserId) async {
    final query1 = await FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .get();

// Luego, busca los documentos donde el array contiene targetUserId
    final query2 = await FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: targetUserId)
        .get();

// Filtra los documentos que están presentes en ambas consultas
    final chatDoc = query1.docs.where((doc) {
      return query2.docs.any((doc2) => doc.id == doc2.id);
    }).toList();

    if (chatDoc.isNotEmpty) {
      return chatDoc.first.id;
    } else {
      // Crea un nuevo chat si no existe
      final chatDocRef = await _firestore.collection('chats').add({
        'users': [currentUserId, targetUserId],
        'isActive': false,
        'isRecent': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return chatDocRef.id;
    }
  }

// Helper function to get existing chat with a user
  Future<Chat?> getExistingChatWithUser(String otherUserId) async {
    final String? currentUserId = await _chatService.getUserId();
    if (currentUserId == null) return null;

    final querySnapshot = await _firestore
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .where('users', arrayContains: otherUserId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final chatDoc = querySnapshot.docs.first;
      return Chat.fromDocument(chatDoc);
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getUserExchanges(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('exchanges')
          .where('senderId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> exchanges = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      return exchanges;
    } catch (e) {
      print('Error al obtener los intercambios: $e');
      rethrow;
    }
  }

  Future<String> updateExchangeStatus({
    required String exchangeId,
    required String status,
  }) async {
    try {
      await _firestore.collection('exchanges').doc(exchangeId).update({
        'status': status,
        'lastModified': FieldValue.serverTimestamp(),
      });
      return "Estado del intercambio actualizado a $status";
    } catch (e) {
      print('Error al actualizar el estado del intercambio: $e');
      return "Error al actualizar el estado del intercambio";
    }
  }

  Future<String> addCounterOffer({
    required String exchangeId,
    required String senderId,
    required List<String> newItemsOffered,
    required List<String> newItemsRequested,
  }) async {
    try {
      DocumentReference counterOfferRef = await _firestore
          .collection('exchanges')
          .doc(exchangeId)
          .collection('counteroffers')
          .add({
        'senderId': senderId,
        'newItemsOffered': newItemsOffered,
        'newItemsRequested': newItemsRequested,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pendiente',
        'points': 200,
      });

      // Actualizamos la última modificación en el documento principal de intercambio
      await _firestore.collection('exchanges').doc(exchangeId).update({
        'lastModified': FieldValue.serverTimestamp(),
      });

      return "Contraoferta añadida con éxito: ${counterOfferRef.id}";
    } catch (e) {
      print('Error al añadir la contraoferta: $e');
      return "Error al añadir la contraoferta";
    }
  }
}
