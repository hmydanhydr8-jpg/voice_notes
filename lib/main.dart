import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

import 'dart:async';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  String formatDuration(Duration duration) {
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  File? playingFile;
  final player = AudioPlayer();
  Future<void> playRecording(File file) async {
    await player.play(DeviceFileSource(file.path));

    setState(() {
      playingFile = file;
    });
  }

  Future<void> pauseRecording() async {
    await player.pause();

    setState(() {
      playingFile = null;
    });
  }

  List<File> recordings = [];
  Future<void> loadRecordings() async {
    final directory = await getApplicationDocumentsDirectory();

    final files = await directory.list().toList();

    recordings = files
        .where((file) => file.path.endsWith('.m4a'))
        .map((file) => File(file.path))
        .toList();
    setState(() {});
  }

  Timer? timer;
  int minute = 0;
  int seconds = 0;
  final recorder = AudioRecorder();
  bool isRecording = false;

  Future<void> startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await recorder.start(const RecordConfig(), path: path);

    setState(() {
      isRecording = true;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (seconds >= 59) {
          minute++;
          seconds = 0;
        } else {
          seconds++;
        }
      });
    });
  }

  Future<void> stopRecording() async {
    await recorder.stop();
    timer?.cancel();
    setState(() {
      isRecording = false;
      seconds = 0;
      minute = 0;
    });
    loadRecordings();
  }

  @override
  void initState() {
    super.initState();
    loadRecordings();

    player.onPlayerComplete.listen((event) {
      setState(() {
        position = Duration.zero;
        playingFile = null;
      });
    });

    player.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });
    player.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("My Record"),
          backgroundColor: Colors.orangeAccent,
        ),
        backgroundColor: const Color.fromARGB(255, 37, 37, 37),
        body: Column(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: IconButton(
                  onPressed: () {
                    if (isRecording) {
                      stopRecording();
                    } else {
                      startRecording();
                    }
                  },
                  icon: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "$seconds : $minute",
                  style: TextStyle(fontSize: 30, color: Colors.white),
                ),
                SizedBox(width: 23),
              ],
            ),
            Divider(color: Colors.white, thickness: 2),
            Expanded(
              child: ListView.builder(
                itemCount: recordings.length,
                itemBuilder: (context, index) {
                  final file = recordings[index];

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(123, 255, 172, 64),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 5,
                            top: 25,
                            child: IconButton(
                              onPressed: () {
                                if (playingFile == file) {
                                  pauseRecording();
                                } else {
                                  playRecording(file);
                                }
                              },
                              icon: Icon(
                                playingFile == file
                                    ? Icons.stop
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 15,
                            left: 70,
                            child: Text(
                              file.path.split('/').last,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            right: 20,
                            left: 50,
                            child: Slider(
                              value: playingFile == file
                                  ? position.inSeconds.toDouble()
                                  : 0,

                              max: playingFile == file
                                  ? duration.inSeconds.toDouble()
                                  : 1,

                              onChanged: playingFile == file
                                  ? (value) {
                                      player.seek(
                                        Duration(seconds: value.toInt()),
                                      );
                                    }
                                  : null,
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 10,
                            child: IconButton(
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text(
                                        'Delete Recording',
                                        style: TextStyle(),
                                      ),
                                      content: const Text(
                                        "Do you want to delete this recording?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldDelete == true) {
                                  await file.delete();
                                  loadRecordings();
                                }
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            left: 55,
                            right: 25,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  playingFile == file
                                      ? formatDuration(position)
                                      : '00:00',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),

                                Text(
                                  playingFile == file
                                      ? formatDuration(duration)
                                      : '_:_',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
