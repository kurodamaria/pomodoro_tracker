import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

void main() {
  runApp(const GetMaterialApp(
    home: Home(),
  ));
}

enum PomodoroTimerStatus {
  initial,
  counting,
  canceled,
  finished,
}

class PomodoroTimer extends GetxController {
  PomodoroTimer(this.totalInSeconds) : remaining$ = totalInSeconds.obs;

  int get remainingSeconds =>
      remaining$.value -
      remainingHours * Duration.secondsPerHour -
      remainingMinutes * Duration.secondsPerMinute;

  int get remainingInSeconds => remaining$.value;

  String get remainingSecondsString => remainingInSeconds.toString();

  int get remainingHours => remainingInSeconds ~/ Duration.secondsPerHour;

  String get remainingHoursString => remainingHours.toString();

  int get remainingMinutes =>
      (remainingInSeconds - remainingHours * Duration.secondsPerHour) ~/
      Duration.secondsPerMinute;

  String get remainingMinutesString => remainingMinutes.toString();

  String get timeString =>
      "${remainingHours < 10 ? '0' : ''}$remainingHours:${remainingMinutes < 10 ? '0' : ''}$remainingMinutes:${remainingSeconds < 10 ? '0' : ''}$remainingSeconds";

  final RxInt remaining$;
  final status$ = PomodoroTimerStatus.initial.obs;

  final int totalInSeconds;
  Timer? _timer;
  static const _kTimerUnitDuration = Duration(seconds: 1);

  void _reduceRemainingOneUnit() {
    // This is where the meaning of the number
    remaining$.value -= _kTimerUnitDuration.inSeconds;
  }

  /// # Start the timer
  /// - initial -> counting
  /// - canceled -> counting
  /// - finished -> counting
  void startTimer() {
    assert(_timer == null && remainingInSeconds > 0,
        'Timer should be null and remaining seconds should be larger than zero');

    status$.value = PomodoroTimerStatus.counting;

    _timer = Timer.periodic(_kTimerUnitDuration, (timer) {
      _reduceRemainingOneUnit();

      if (remainingInSeconds == 0) {
        timer.cancel();
        _timer = null;
        remaining$.value = totalInSeconds;
        status$.value = PomodoroTimerStatus.finished;
      }
    });
  }

  void cancelTimer() {
    assert(_timer != null && remainingInSeconds > 0,
        'There should be a timer running and the remaining seconds is larger than 0');

    _timer!.cancel();
    _timer = null;
    remaining$.value = totalInSeconds;
    status$.value = PomodoroTimerStatus.canceled;
  }

  void cancelOrStartTimer() {
    if (status$.value == PomodoroTimerStatus.counting) {
      cancelTimer();
    } else {
      startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class PomodoroTask extends HiveObject {
  PomodoroTask({
    required this.id,
    required this.title,
    required this.pomodoroCount,
    required this.finishedPomodoroCount,
    required this.category,
  });

  int id;
  String title;
  int pomodoroCount;
  int finishedPomodoroCount;
  String category;
}

class LogPage extends StatelessWidget {
  const LogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.grid_view),
            tooltip: 'Switch View',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text('2021-12-05', style: Get.textTheme.headline6),
            SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const <DataColumn>[
                  DataColumn(
                    label: Text(
                      'Timestamp',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Event Type',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                rows: <DataRow>[
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Chip(label: Text('03:25:03'))),
                      DataCell(Text('Delete Pomodoro')),
                    ],
                  ),
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('03:25:03')),
                      DataCell(Text('Cancel Pomodoro')),
                    ],
                  ),
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('03:25:03')),
                      DataCell(Text('Add Emergency Pomodoro')),
                    ],
                  ),
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('03:25:03')),
                      DataCell(Text('Reorder Task')),
                    ],
                  ),
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('03:25:03')),
                      DataCell(Text('Cancel Pomodoro (App)'), onTap: () {
                        Get.bottomSheet(EventDetailCard());
                      }),
                    ],
                  ),
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('03:25:03')),
                      DataCell(Text('Start Pomodoro (User)')),
                    ],
                  ),
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('03:25:03')),
                      DataCell(Text('Start Pomodoro (App)')),
                    ],
                  ),
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('03:25:03')),
                      DataCell(Text('Cancel Pomodoro (App)')),
                    ],
                  ),
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('03:25:03')),
                      DataCell(Text('Cancel Pomodoro (User)')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventDetailCard extends StatelessWidget {
  const EventDetailCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            child: Text('Event Detail', style: Get.textTheme.headline5),
            alignment: Alignment.topCenter,
          ),
          Text('Type: Cancel Pomodoro (App)'),
          Text('Time: 2021-12-05 03:25:03'),
          Text('Reason: The app was killed when the below task is running'),
          PomodoroTaskListTile(task: Get.find<PomodoroTaskProvider>().tasks.first),
          Text('Tip: If it was not you that kill the app from task view, '
              'enable always run in background and background lock for the app.'),
          Chip(label: Text('Always Run in Background')),
          Chip(label: Text('Background Lock')),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              child: Text('OK'),
              onPressed: () {
                Get.back();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Log extends HiveObject {}

abstract class PomodoroEvent {}

class PomodoroTaskProvider extends GetxController {
  List<PomodoroTask> tasks = [
    PomodoroTask(
        id: 0,
        title: "Introduction to algorithm, 3e",
        pomodoroCount: 4,
        finishedPomodoroCount: 0,
        category: "study"),
    PomodoroTask(
        id: 1,
        title: "The Art of Computer Programming, 4e",
        pomodoroCount: 4,
        finishedPomodoroCount: 2,
        category: "study"),
    PomodoroTask(
        id: 2,
        title: "Introduction to algorithm, 3e",
        pomodoroCount: 4,
        finishedPomodoroCount: 0,
        category: "entertainment"),
    PomodoroTask(
        id: 3,
        title: "Introduction to algorithm, 3e",
        pomodoroCount: 4,
        finishedPomodoroCount: 2,
        category: "study"),
  ];
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin<Home> {
  final controller = Get.put(PomodoroTimer(25 * 60));
  final taskProvider = Get.put(PomodoroTaskProvider());
  late final AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        vsync: this, duration: Duration(seconds: controller.totalInSeconds));
    controller.status$.listen((p0) {
      if (p0 == PomodoroTimerStatus.counting) {
        animationController.forward();
      } else {
        animationController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pomodoro'),
        actions: [
          IconButton(
              onPressed: () {
                Get.to(LogPage());
              },
              icon: Icon(Icons.nine_k_sharp)),
          IconButton(
            onPressed: () {
              Get.dialog(
                AddTaskDialogWidget(),
              );
            },
            icon: Icon(Icons.alarm),
            tooltip: 'Add new emergency task',
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.add),
            tooltip: 'Add new task',
          ),
        ],
      ),
      bottomSheet: PomodoroTaskManager(),
      body: Align(
        alignment: Alignment(0, -0.9),
        child: InkWell(
          onLongPress: () {
            controller.cancelTimer();
          },
          onTap: () {
            if (controller.status$.value != PomodoroTimerStatus.counting) {
              controller.startTimer();
            }
          },
          child: Stack(
            children: [
              SizedBox(
                width: Get.mediaQuery.size.width * 0.8,
                height: Get.mediaQuery.size.width * 0.8,
                child: AnimatedCircularProgressIndicator(
                  controller: animationController,
                ),
              ),
              Positioned.fill(
                child: Center(child: Obx(() {
                  return Text('${controller.timeString}',
                      style: Get.textTheme.headline2);
                })),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedCircularProgressIndicator extends StatefulWidget {
  const AnimatedCircularProgressIndicator({Key? key, required this.controller})
      : super(key: key);

  final AnimationController controller;

  @override
  State<AnimatedCircularProgressIndicator> createState() =>
      _AnimatedCircularProgressIndicatorState();
}

class _AnimatedCircularProgressIndicatorState
    extends State<AnimatedCircularProgressIndicator> {
  late final Animation animation;

  @override
  void initState() {
    super.initState();
    animation = widget.controller.drive(Tween<double>(begin: 0, end: 1));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animation,
        builder: (context, staticChild) {
          return CircularProgressIndicator(
            strokeWidth: 10,
            value: animation.value,
            color: Colors.red,
            backgroundColor: Colors.grey[200],
          );
        });
  }
}

class AddTaskDialogWidget extends StatelessWidget {
  const AddTaskDialogWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 8, vertical: Get.mediaQuery.size.height / 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text('Add new item', style: Get.textTheme.headline5),
              TextField(),
              TextField(
                maxLines: 6,
                minLines: 6,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PomodoroTaskManager extends StatefulWidget {
  const PomodoroTaskManager({Key? key}) : super(key: key);

  @override
  State<PomodoroTaskManager> createState() => _PomodoroTaskManagerState();
}

class _PomodoroTaskManagerState extends State<PomodoroTaskManager> {
  final taskProvider = Get.find<PomodoroTaskProvider>();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 30,
      child: ReorderableListView(
        shrinkWrap: true,
        onReorder: (int oldIndex, int newIndex) {
          if (Get.find<PomodoroTimer>().status$.value ==
              PomodoroTimerStatus.counting) {
            if (Get.isSnackbarOpen == false) {
              Get.snackbar(
                  'Reorder Failed',
                  'You cannot reorder tasks while you are in a pomodoro. '
                      'Cancel the current pomodoro to perform this action.');
            }
            return;
          }
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = taskProvider.tasks.removeAt(oldIndex);
            taskProvider.tasks.insert(newIndex, item);
          });
        },
        children: taskProvider.tasks
            .map((task) =>
                PomodoroTaskListTile(key: ValueKey(task.id), task: task))
            .toList(),
      ),
    );
  }
}

class PomodoroTaskListTile extends StatelessWidget {
  const PomodoroTaskListTile({Key? key, required this.task}) : super(key: key);

  final PomodoroTask task;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Get.bottomSheet(PomodoroTaskDetailCard(task: task));
      },
      // onLongPress: () {
      //   // todo long press to drag
      // },
      title: Text(task.title),
      leading: Stack(
        children: [
          CircularProgressIndicator(
            value: task.finishedPomodoroCount / task.pomodoroCount,
            backgroundColor: Colors.grey,
          ),
          Positioned.fill(
            child: Center(
                child: Text(
                    '${task.finishedPomodoroCount}/${task.pomodoroCount}')),
          )
        ],
      ),
    );
  }
}

class PomodoroTaskDetailCard extends StatelessWidget {
  const PomodoroTaskDetailCard({Key? key, required this.task})
      : super(key: key);

  final PomodoroTask task;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Task Detail',
              style: Theme.of(context).textTheme.headline5,
            ),
            TextField(
              decoration: InputDecoration(hintText: task.title),
            ),
            TextField(
              decoration: InputDecoration(hintText: 'description'),
              minLines: 7,
              maxLines: 7,
            ),
          ],
        ),
      ),
    );
  }
}
