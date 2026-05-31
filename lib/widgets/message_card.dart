import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';

import '../api/apis.dart';
import '../helper/dialogs.dart';
import '../helper/my_date_util.dart';
import '../main.dart';
import '../models/message.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});
  final Message message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = APIs.user.uid == widget.message.fromId;
    return InkWell(
      onLongPress: () => _showBottomSheet(isMe),
      child: isMe ? _myMessage() : _theirMessage(),
    );
  }

  Widget _theirMessage() {
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: mq.width * .03, vertical: mq.height * .005),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: mq.width * .75),
              padding: EdgeInsets.all(
                  widget.message.type == Type.image
                      ? mq.width * .02
                      : mq.width * .03),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                  bottomLeft: Radius.circular(2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContent(),
                  const SizedBox(height: 3),
                  Text(
                    MyDateUtil.getFormattedTime(
                        context: context,
                        time: widget.message.sent),
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _myMessage() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: mq.width * .03, vertical: mq.height * .005),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: mq.width * .75),
              padding: EdgeInsets.all(
                  widget.message.type == Type.image
                      ? mq.width * .02
                      : mq.width * .03),
              decoration: const BoxDecoration(
                color: Color(0xFFDCF8C6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildContent(),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        MyDateUtil.getFormattedTime(
                            context: context,
                            time: widget.message.sent),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all_rounded,
                        size: 16,
                        color: widget.message.read.isNotEmpty
                            ? const Color(0xFF34B7F1)
                            : Colors.black45,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.message.type) {
      case Type.text:
        return Text(
          widget.message.msg,
          style: const TextStyle(
              fontSize: 15, color: Colors.black87),
        );
      case Type.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: widget.message.msg,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF075E54),
              ),
            ),
            errorWidget: (context, url, error) =>
                const Icon(Icons.image, size: 70),
          ),
        );
      case Type.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic,
                color: Color(0xFF075E54), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Mensagem de voz',
              style: TextStyle(
                  fontSize: 14, color: Colors.black54),
            ),
          ],
        );
    }
  }

  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: [
            Container(
              height: 4,
              margin: EdgeInsets.symmetric(
                  vertical: mq.height * .015,
                  horizontal: mq.width * .4),
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius:
                    BorderRadius.all(Radius.circular(8)),
              ),
            ),
            if (widget.message.type == Type.text)
              _OptionItem(
                icon: const Icon(Icons.copy_all_rounded,
                    color: Color(0xFF075E54), size: 26),
                name: 'Copiar texto',
                onTap: (ctx) async {
                  await Clipboard.setData(ClipboardData(
                          text: widget.message.msg))
                      .then((value) {
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      Dialogs.showSnackbar(
                          ctx, 'Texto copiado!');
                    }
                  });
                },
              )
            else if (widget.message.type == Type.image)
              _OptionItem(
                icon: const Icon(Icons.download_rounded,
                    color: Color(0xFF075E54), size: 26),
                name: 'Salvar imagem',
                onTap: (ctx) async {
                  try {
                    await GallerySaver.saveImage(
                            widget.message.msg,
                            albumName: 'We Chat')
                        .then((success) {
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (success != null && success) {
                          Dialogs.showSnackbar(
                              ctx, 'Imagem salva!');
                        }
                      }
                    });
                  } catch (e) {
                    log('ErrorWhileSavingImg: $e');
                  }
                },
              ),
            if (isMe)
              Divider(
                color: Colors.black12,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),
            if (widget.message.type == Type.text && isMe)
              _OptionItem(
                icon: const Icon(Icons.edit,
                    color: Color(0xFF075E54), size: 26),
                name: 'Editar mensagem',
                onTap: (ctx) {
                  if (ctx.mounted) {
                    _showMessageUpdateDialog(ctx);
                  }
                },
              ),
            if (isMe)
              _OptionItem(
                icon: const Icon(Icons.delete_forever,
                    color: Colors.red, size: 26),
                name: 'Apagar mensagem',
                onTap: (ctx) async {
                  await APIs.deleteMessage(widget.message)
                      .then((_) {
                    if (ctx.mounted) Navigator.pop(ctx);
                  });
                },
              ),
            Divider(
              color: Colors.black12,
              endIndent: mq.width * .04,
              indent: mq.width * .04,
            ),
            _OptionItem(
              icon: const Icon(Icons.access_time,
                  color: Color(0xFF075E54)),
              name:
                  'Enviado: ${MyDateUtil.getMessageTime(time: widget.message.sent)}',
              onTap: (_) {},
            ),
            _OptionItem(
              icon: Icon(Icons.done_all_rounded,
                  color: widget.message.read.isNotEmpty
                      ? const Color(0xFF34B7F1)
                      : Colors.black45),
              name: widget.message.read.isEmpty
                  ? 'Lido: ainda não visto'
                  : 'Lido: ${MyDateUtil.getMessageTime(time: widget.message.read)}',
              onTap: (_) {},
            ),
          ],
        );
      },
    );
  }

  void _showMessageUpdateDialog(final BuildContext ctx) {
    String updatedMsg = widget.message.msg;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.only(
            left: 24, right: 24, top: 20, bottom: 10),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(20))),
        title: const Row(
          children: [
            Icon(Icons.edit,
                color: Color(0xFF075E54), size: 28),
            Text(' Editar mensagem'),
          ],
        ),
        content: TextFormField(
          initialValue: updatedMsg,
          maxLines: null,
          onChanged: (value) => updatedMsg = value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(15)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () {
              APIs.updateMessage(widget.message, updatedMsg);
              Navigator.pop(ctx);
              Navigator.pop(ctx);
            },
            child: const Text('Atualizar',
                style: TextStyle(
                    color: Color(0xFF075E54),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final Function(BuildContext) onTap;

  const _OptionItem(
      {required this.icon,
      required this.name,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(context),
      child: Padding(
        padding: EdgeInsets.only(
            left: mq.width * .05,
            top: mq.height * .015,
            bottom: mq.height * .015),
        child: Row(
          children: [
            icon,
            Flexible(
              child: Text(
                '    $name',
                style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
