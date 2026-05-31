import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:just_audio/just_audio.dart';

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
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _played = false;

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (_isLoading) return;

    try {
      setState(() => _isLoading = true);

      _audioPlayer ??= AudioPlayer();

      if (_isPlaying) {
        await _audioPlayer!.pause();
        setState(() => _isPlaying = false);
        return;
      }

      await _audioPlayer!.setUrl(widget.message.msg);

      _duration = _audioPlayer!.duration ?? Duration.zero;

      _audioPlayer!.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });

      _audioPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
            });

            // Marca como reproduzido e agenda deleção em 5s
            if (!_played) {
              _played = true;
              final isMe =
                  APIs.user.uid == widget.message.fromId;
              if (!isMe) {
                APIs.markAudioPlayed(widget.message);
              }
            }
          }
        }
      });

      await _audioPlayer!.play();
      setState(() {
        _isPlaying = true;
        _isLoading = false;
      });
    } catch (e) {
      log('playAudioE: $e');
      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

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
          style:
              const TextStyle(fontSize: 15, color: Colors.black87),
        );

      case Type.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: widget.message.msg,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Padding(
