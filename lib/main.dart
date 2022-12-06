import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: RecorderScreen(),
    );
  }
}

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  final recorder = FlutterSoundRecorder();
  File? audioFile;
  bool isStop = false;

  @override
  void initState() {
    super.initState();

    initRecorder();
  } 
// initializing recorder and user permission
  Future initRecorder() async {
    final permissionsGranted = await Permission.microphone.request();
    final status = await Permission.storage.request();
    if (permissionsGranted == PermissionStatus.granted &&
        status == PermissionStatus.granted) {
      await recorder.openRecorder();

      recorder.setSubscriptionDuration(
        const Duration(milliseconds: 500),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    recorder.closeRecorder();
  }
  // to start recording
  Future record() async {
    Directory directory = Directory(path.dirname('/storage/emulated/0/audio'));
    if (!directory.existsSync()) {
      directory.createSync();
    }
    await recorder.startRecorder(
      toFile: '/storage/emulated/0/audio',
    );
  }
 // to end recording
  Future stop() async {
    final path = await recorder.stopRecorder();
    final audiofile = File(path!);
    print(audiofile);
    setState(() {
      isStop = true;
      audioFile = audiofile;
    });
  }

  String _duration(Duration duration) {
    String twoDigiits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigiits(duration.inHours);
    final minutes = twoDigiits(duration.inMinutes.remainder(60));
    final seconds = twoDigiits(duration.inSeconds.remainder(60));

    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(':');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // duration of recording
          StreamBuilder<RecordingDisposition>(
              stream: recorder.onProgress,
              builder: (context, snapshot) {
                final duration =
                    snapshot.hasData ? snapshot.data!.duration : Duration.zero;
                return Text('${_duration(duration)}');
              }),
          const SizedBox(
            height: 10,
          ),
          // button to start and stop recording
          Center(
            child: CircleAvatar(
              child: IconButton(
                icon: Icon(recorder.isRecording ? Icons.stop : Icons.mic),
                onPressed: () async {
                  if (recorder.isRecording) {
                    await stop();
                  } else {
                    await record();
                  }
                  setState(() {});
                },
              ),
            ),
          ),
          // Once recorded then to share it from app
          if (isStop)
            IconButton(
                onPressed: () async {
                  print(audioFile!.path);
                  await Share.shareFiles(
                      [audioFile!.path]);
                },
                icon: Icon(Icons.share))
        ],
      ),
    );
  }
}
