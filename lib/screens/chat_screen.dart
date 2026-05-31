import 'dart:developer';
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../api/apis.dart';
import '../helper/my_date_util.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../widgets/message_card.dart';
import '../widgets/profile_image.dart';
import 'view_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _list = [];
  final _textController = TextEditingController();
  bool _showEmoji = false, _isUploading = false;
  bool _isRecording = false;
  bool _hasText = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() => _hasText = _textController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) {
          if (_showEmoji) {
            setState(() => _showEmoji = !_showEmoji);
            return;
          }
          Future.delayed(const Duration(milliseconds: 300), () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          });
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF075E54),
            flexibleSpace: _appBar(),
          ),
          body: Container(
            color: const Color(0xFFECE5DD),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder(
                      stream: APIs.getAllMessages(widget.user),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                          case ConnectionState.none:
                            return const SizedBox();
                          case ConnectionState.active:
                          case ConnectionState.done:
                            final data = snapshot.data?.docs;
                            _list = data
                                    ?.map((e) =>
                                        Message.fromJson(e.data()))
                                    .toList() ??
                                [];
                            if (_list.isNotEmpty) {
                              return ListView.builder(
                                reverse: true,
                                itemCount: _list.length,
                                padding: EdgeInsets.only(
                                    top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return MessageCard(
                                      message: _list[index]);
                                },
                              );
                            } else {
                              return const Center(
                                child: Text('Say Hii! 👋',
                                    style: TextStyle(fontSize: 20)),
                              );
                            }
                        }
                      },
                    ),
                  ),
                  if (_isUploading)
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 8, horizontal: 20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF075E54),
                        ),
                      ),
                    ),
                  if (_isRecording)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.mic,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Gravando...',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Solte para enviar',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  _chatInput(),
                  if (_showEmoji)
                    SizedBox(
                      height: mq.height * .35,
                      child: EmojiPicker(
                        textEditingController: _textController,
                        config: const Config(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return SafeArea(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ViewProfileScreen(user: widget.user)),
        ),
        child: StreamBuilder(
          stream: APIs.getUserInfo(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list = data
                    ?.map((e) => ChatUser.fromJson(e.data()))
                    .toList() ??
                [];
            return Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white),
                ),
                ProfileImage(
                  size: mq.height * .05,
                  url: list.isNotEmpty
                      ? list[0].image
                      : widget.user.image,
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.isNotEmpty
                          ? list[0].name
                          : widget.user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      list.isNotEmpty
                          ? list[0].isOnline
                              ? 'Online'
                              : MyDateUtil.getLastActiveTime(
                                  context: context,
                                  lastActive: list[0].lastActive)
                          : MyDateUtil.getLastActiveTime(
                              context: context,
                              lastActive: widget.user.lastActive),
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: mq.height * .01,
        horizontal: mq.width * .025,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _showEmoji = !_showEmoji);
                    },
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Color(0xFF075E54),
                      size: 25,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () {
                        if (_showEmoji) {
                          setState(() => _showEmoji = false);
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Mensagem',
                        hintStyle:
                            TextStyle(color: Colors.black38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final List<XFile> images =
                          await picker.pickMultiImage(
                              imageQuality: 70);
                      for (var i in images) {
                        setState(() => _isUploading = true);
                        await APIs.sendChatImage(
                            widget.user, File(i.path));
                        setState(() => _isUploading = false);
                      }
                    },
                    icon: const Icon(
                      Icons.attach_file_rounded,
                      color: Color(0xFF075E54),
                      size: 26,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 70,
                      );
                      if (image != null) {
                        setState(() => _isUploading = true);
                        await APIs.sendChatImage(
                            widget.user, File(image.path));
                        setState(() => _isUploading = false);
                      }
                    },
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF075E54),
                      size: 26,
                    ),
                  ),
                  SizedBox(width: mq.width * .01),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _hasText ? _sendTextMessage : null,
            onLongPressStart:
                !_hasText ? (_) => _startRecording() : null,
            onLongPressEnd:
                !_hasText ? (_) => _stopRecording() : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red
                    : const Color(0xFF075E54),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _hasText
                    ? Icons.send_rounded
                    : _isRecording
                        ? Icons.mic
                        : Icons.mic_none_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendTextMessage() {
    if (_textController.text.isNotEmpty) {
      if (_list.isEmpty) {
        APIs.sendFirstMessage(
            widget.user, _textController.text, Type.text);
      } else {
        APIs.sendMessage(
            widget.user, _textController.text, Type.text);
      }
      _textController.text = '';
    }
  }

  Future<void> _startRecording() async {
    final hasPermission =
        await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Permissão de microfone negada')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordingPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordingPath!,
    );
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null) {
      final file = File(path);
      setState(() => _isUploading = true);
      await APIs.sendChatAudio(widget.user, file);
      setState(() => _isUploading = false);
    }
  }
}
