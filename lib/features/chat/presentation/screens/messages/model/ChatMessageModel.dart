enum ChatMessageType { text, image, audio, video, notification }

enum MessageStatus { notSent, notViewed, viewed }

class ChatMessageModel {
  final String id; // Unique identifier for the message
  final ChatMessageType type;
  final String content; // For text, image, or audio
  final String sender; // ID of the user who sent the message
  final MessageStatus status;
  final DateTime timestamp; // Timestamp of when the message was sent

  ChatMessageModel({
    required this.id,
    required this.type,
    required this.content,
    required this.sender,
    required this.status,
    required this.timestamp, // Initialize timestamp
  });
}
