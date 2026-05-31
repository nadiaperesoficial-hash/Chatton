import 'package:flutter/material.dart';

import '../api/apis.dart';
import '../helper/my_date_util.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../screens/chat_screen.dart';
import 'dialogs/profile_dialog.dart';
import 'profile_image.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChatScreen(user: widget.user)),
      ),
      child: StreamBuilder(
        stream: APIs.getLastMessage(widget.user),
        builder: (context, snapshot) {
          final data = snapshot.data?.docs;
          final list = data
                  ?.map((e) => Message.fromJson(e.data()))
                  .toList() ??
              [];
          if (list.isNotEmpty) _message = list[0];

          final bool isUnread = _message != null &&
              _message!.read.isEmpty &&
              _message!.fromId != APIs.user.uid;

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: mq.width * .04,
              vertical: mq.height * .012,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) =>
                        ProfileDialog(user: widget.user),
                  ),
                  child: ProfileImage(
                    size: mq.height * .062,
                    url: widget.user.image,
                  ),
                ),

                const SizedBox(width: 12),

                // Nome + última mensagem
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Última mensagem
                      Row(
                        children: [
                          // Ícone de tipo
                          if (_message != null &&
                              _message!.fromId == APIs.user.uid)
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.done_all_rounded,
                                size: 16,
                                color: _message!.read.isNotEmpty
                                    ? const Color(0xFF34B7F1)
                                    : Colors.grey,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              _message == null
                                  ? widget.user.about
                                  : _message!.type == Type.image
                                      ? '📷 Foto'
                                      : _message!.type == Type.audio
                                          ? '🎵 Áudio'
                                          : _message!.msg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isUnread
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                                fontWeight: isUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Hora + badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Hora
                    Text(
                      _message == null
                          ? ''
                          : MyDateUtil.getLastMessageTime(
                              context: context,
                              time: _message!.sent),
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread
                            ? const Color(0xFF075E54)
                            : Colors.grey.shade500,
                        fontWeight: isUnread
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Badge mensagem não lida
                    if (isUnread)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF075E54),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
