import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../api/apis.dart';
import '../helper/dialogs.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../widgets/chat_user_card.dart';
import '../widgets/profile_image.dart';
import 'ai_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChatUser> _list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }
      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) {
          if (_isSearching) {
            setState(() => _isSearching = !_isSearching);
            return;
          }
          Future.delayed(
              const Duration(milliseconds: 300), SystemNavigator.pop);
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF075E54),
            elevation: 0,
            leading: IconButton(
              tooltip: 'Ver perfil',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProfileScreen(user: APIs.me)),
              ),
              icon: const ProfileImage(size: 32),
            ),
            title: _isSearching
                ? TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Buscar...',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7)),
                    ),
                    autofocus: true,
                    style: const TextStyle(
                        fontSize: 17,
                        letterSpacing: 0.5,
                        color: Colors.white),
                    onChanged: (val) {
                      _searchList.clear();
                      val = val.toLowerCase();
                      for (var i in _list) {
                        if (i.name.toLowerCase().contains(val) ||
                            i.email.toLowerCase().contains(val)) {
                          _searchList.add(i);
                        }
                      }
                      setState(() => _searchList);
                    },
                  )
                : const Text(
                    'Chatton',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
            actions: [
              IconButton(
                tooltip: 'Buscar',
                onPressed: () =>
                    setState(() => _isSearching = !_isSearching),
                icon: Icon(
                  _isSearching
                      ? CupertinoIcons.clear_circled_solid
                      : CupertinoIcons.search,
                  color: Colors.white,
                ),
              ),
              IconButton(
                tooltip: 'Adicionar usuário',
                padding: const EdgeInsets.only(right: 8),
                onPressed: _addChatUserDialog,
                icon: const Icon(
                  CupertinoIcons.person_add,
                  size: 25,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF075E54),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiScreen()),
              ),
              child: Lottie.asset('assets/lottie/ai.json', width: 40),
            ),
          ),
          body: StreamBuilder(
            stream: APIs.getMyUsersId(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF075E54),
                    ),
                  );
                case ConnectionState.active:
                case ConnectionState.done:
                  return StreamBuilder(
                    stream: APIs.getAllUsers(
                      snapshot.data?.docs
                              .map((e) => e.id)
                              .toList() ??
                          [],
                    ),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          _list = data
                                  ?.map((e) =>
                                      ChatUser.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                              itemCount: _isSearching
                                  ? _searchList.length
                                  : _list.length,
                              padding: EdgeInsets.only(
                                  top: mq.height * .01),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return ChatUserCard(
                                  user: _isSearching
                                      ? _searchList[index]
                                      : _list[index],
                                );
                              },
                            );
                          } else {
                            return const Center(
                              child: Text(
                                'Nenhuma conversa ainda',
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black54),
                              ),
                            );
                          }
                      }
                    },
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  void _addChatUserDialog() {
    String email = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.only(
            left: 24, right: 24, top: 20, bottom: 10),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15))),
        title: const Row(
          children: [
            Icon(Icons.person_add,
                color: Color(0xFF075E54), size: 28),
            Text('  Adicionar usuário'),
          ],
        ),
        content: TextFormField(
          maxLines: null,
          onChanged: (value) => email = value,
          decoration: const InputDecoration(
            hintText: 'E-mail',
            prefixIcon: Icon(Icons.email,
                color: Color(0xFF075E54)),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(15)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (email.trim().isNotEmpty) {
                await APIs.addChatUser(email).then((value) {
                  if (!value) {
                    Dialogs.showSnackbar(
                        context, 'Usuário não encontrado!');
                  }
                });
              }
            },
            child: const Text(
              'Adicionar',
              style: TextStyle(
                color: Color(0xFF075E54),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
