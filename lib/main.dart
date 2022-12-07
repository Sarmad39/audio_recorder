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
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RecorderScreen(),
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
  String filePath = '/storage/emulated/0/temp1.wav';

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
    Directory dir = Directory(path.dirname(filePath));
    if (!dir.existsSync()) {
      dir.createSync();
    }

    await recorder.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
    );
  }

  // to end recording
  Future stop() async {
    await recorder.stopRecorder();
      setState(() {
        isStop = true;
        audioFile = File(filePath);
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // duration of recording
          StreamBuilder<RecordingDisposition>(
              stream: recorder.onProgress,
              builder: (context, snapshot) {
                final duration =
                    snapshot.hasData ? snapshot.data!.duration : Duration.zero;
                print(duration.inSeconds);
                return Text(
                  _duration(duration),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                );
              }),
          const SizedBox(
            height: 10,
          ),
          // button to start and stop recording
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(5.0),
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                    color: Colors.orange,
                    width: 3.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 10.0,
                ),
                onPressed: recorder.isRecording
                    ? null
                    : () async {
                        await record();
                        setState(() {
                          isStop = false;
                        });
                      },
                icon: const Icon(
                  Icons.mic,
                  color: Colors.red,
                  size: 35.0,
                ),
                label: const Text(''),
              ),
              const SizedBox(
                width: 10,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(5.0),
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                    color: Colors.orange,
                    width: 3.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 10.0,
                ),
                onPressed: recorder.isRecording
                    ? () async {
                        await stop();
                        setState(() {});
                      }
                    : null,
                icon: const Icon(
                  Icons.stop,
                  color: Colors.black,
                  size: 35.0,
                ),
                label: const Text(''),
              ),
            ],
          ),
          // Once recorded then to share it from app
          const SizedBox(
            height: 10,
          ),
          if (isStop)
            Row(
              children: [
                Flexible(
                    child: TextField(
                  readOnly: true,
                  decoration:
                      InputDecoration(hintText: 'File path : $filePath'),
                )),
                IconButton(
                    onPressed: () async {
                      await Share.shareFiles([audioFile!.path]);
                    },
                    icon: const Icon(Icons.share)),
              ],
            )
        ],
      ),
    );
  }
}
