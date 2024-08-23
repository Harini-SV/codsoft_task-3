import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class ExampleAlarmEditScreen extends StatefulWidget {
  final AlarmSettings? alarmSettings;

  const ExampleAlarmEditScreen({Key? key, this.alarmSettings}) : super(key: key);

  @override
  State<ExampleAlarmEditScreen> createState() => _ExampleAlarmEditScreenState();
}

class _ExampleAlarmEditScreenState extends State<ExampleAlarmEditScreen> {
  bool loading = false;
  late bool creating;
  late bool loopAudio;
  late bool vibrate;
  late double? volume;
  late String assetAudio;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _ampmController;

  late int hour;
  late int minute;
  late String amPm;
  late DateTime selectedDateTime; // Added this variable

  @override
  void initState() {
    super.initState();
    creating = widget.alarmSettings == null;

    if (creating) {
      selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
      selectedDateTime = selectedDateTime.copyWith(second: 0, millisecond: 0);
      loopAudio = true;
      vibrate = true;
      volume = null;
      assetAudio = 'assets/marimba.mp3';
    } else {
      selectedDateTime = widget.alarmSettings!.dateTime;
      loopAudio = widget.alarmSettings!.loopAudio;
      vibrate = widget.alarmSettings!.vibrate;
      volume = widget.alarmSettings!.volume;
      assetAudio = widget.alarmSettings!.assetAudioPath;
    }

    hour = selectedDateTime.hour % 12;
    minute = selectedDateTime.minute;
    amPm = selectedDateTime.hour >= 12 ? 'PM' : 'AM';

    _minuteController = FixedExtentScrollController(initialItem: minute);
    _hourController = FixedExtentScrollController(initialItem: hour);
    _ampmController = FixedExtentScrollController(initialItem: amPm == 'PM' ? 1 : 0);
  }

  @override
  void dispose() {
    _minuteController.dispose();
    _hourController.dispose();
    _ampmController.dispose();
    super.dispose();
  }

  String getDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = selectedDateTime.difference(today).inDays;

    switch (difference) {
      case 0:
        return 'Today - ${DateFormat('EEE, d MMM').format(selectedDateTime)}';
      case 1:
        return 'Tomorrow - ${DateFormat('EEE, d MMM').format(selectedDateTime)}';
      default:
        return DateFormat('EEE, d MMM').format(selectedDateTime);
    }
  }

  Future<void> pickTime() async {
    final res = await showTimePicker(
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      context: context,
    );

    if (res != null) {
      setState(() {
        final DateTime now = DateTime.now();
        selectedDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          res.hour,
          res.minute,
        );
        if (selectedDateTime.isBefore(now)) {
          selectedDateTime = selectedDateTime.add(const Duration(days: 1));
        }

        hour = selectedDateTime.hour % 12;
        minute = selectedDateTime.minute;
        amPm = selectedDateTime.hour >= 12 ? 'PM' : 'AM';

        _minuteController.jumpToItem(minute);
        _hourController.jumpToItem(hour);
        _ampmController.jumpToItem(amPm == 'PM' ? 1 : 0);
      });
    }
  }

  AlarmSettings buildAlarmSettings() {
    final id = creating
        ? DateTime.now().millisecondsSinceEpoch % 10000
        : widget.alarmSettings!.id;

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: selectedDateTime,
      loopAudio: loopAudio,
      vibrate: vibrate,
      volume: volume,
      assetAudioPath: assetAudio,
      notificationTitle: 'Alarm example',
      notificationBody: 'Your alarm ($id) is ringing',
    );
    return alarmSettings;
  }

  void saveAlarm() {
    if (loading) return;
    setState(() => loading = true);
    Alarm.set(alarmSettings: buildAlarmSettings()).then((res) {
      if (res) Navigator.pop(context, true);
      setState(() => loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Flexible(
            flex: 1,
            child: Row(
              children: [
                Flexible(
                  flex: 1,
                  child: CupertinoPicker(
                    squeeze: 0.8,
                    diameterRatio: 5,
                    useMagnifier: true,
                    looping: true,
                    itemExtent: 100,
                    scrollController: _hourController,
                    selectionOverlay:
                        const CupertinoPickerDefaultSelectionOverlay(
                      background: Colors.transparent,
                      capEndEdge: true,
                    ),
                    onSelectedItemChanged: (value) {
                      setState(() {
                        hour = value + 1;
                        if (hour == 12) hour = 0; // Adjust to handle 12-hour format
                        _updateDateTime();
                      });
                    },
                    children: [
                      for (int i = 1; i <= 12; i++) ...[
                        Center(
                          child: Text(
                            '$i',
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Text(
                  ":",
                  style: TextStyle(fontSize: 50),
                ),
                Flexible(
                  flex: 1,
                  child: CupertinoPicker(
                    squeeze: 0.8,
                    diameterRatio: 5,
                    looping: true,
                    itemExtent: 100,
                    scrollController: _minuteController,
                    selectionOverlay:
                        const CupertinoPickerDefaultSelectionOverlay(
                      background: Colors.transparent,
                      capEndEdge: true,
                    ),
                    onSelectedItemChanged: (value) {
                      setState(() {
                        minute = value;
                        _updateDateTime();
                      });
                    },
                    children: [
                      for (int i = 0; i <= 59; i++) ...[
                        Center(
                          child: Text(
                            i.toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: CupertinoPicker(
                    squeeze: 1,
                    diameterRatio: 15,
                    useMagnifier: true,
                    itemExtent: 100,
                    scrollController: _ampmController,
                    selectionOverlay:
                        const CupertinoPickerDefaultSelectionOverlay(
                      background: Colors.transparent,
                    ),
                    onSelectedItemChanged: (value) {
                      setState(() {
                        amPm = value == 0 ? 'AM' : 'PM';
                        _updateDateTime();
                      });
                    },
                    children: [
                      for (var i in ['AM', 'PM']) ...[
                        Center(
                          child: Text(
                            i,
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(getDay()),
                      trailing: IconButton(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_month_outlined)),
                    ),
                    ListTile(
                      title: const Text("Alarm Sound"),
                      trailing: DropdownButton(
                        value: assetAudio,
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'assets/marimba.mp3',
                            child: Text('Marimba'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'assets/nokia.mp3',
                            child: Text('Nokia'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'assets/mozart.mp3',
                            child: Text('Mozart'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'assets/star_wars.mp3',
                            child: Text('Star Wars'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'assets/one_piece.mp3',
                            child: Text('One Piece'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => assetAudio = value!),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Divider(),
                    ),
                    ListTile(
                      title: const Text("Vibration"),
                      trailing: Switch(
                          inactiveThumbColor: null,
                          value: vibrate,
                          onChanged: (value) =>
                              setState(() => vibrate = value)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Divider(),
                    ),
                    ListTile(
                      title: const Text("Volume level"),
                      trailing: Switch(
                        value: volume != null,
                        onChanged: (value) =>
                            setState(() => volume = value ? 0.5 : null),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: volume != null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    volume! > 0.7
                                        ? Icons.volume_up_rounded
                                        : volume! > 0.1
                                            ? Icons.volume_down_rounded
                                            : Icons.volume_mute_rounded,
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: volume!,
                                      onChanged: (value) {
                                        setState(() => volume = value);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(),
                    ),
                    const SizedBox(),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.blue)),
                ),
              ),
              SizedBox(
                child: ElevatedButton(
                  onPressed: saveAlarm,
                  child: const Text("Save", style: TextStyle(color: Colors.blue)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateDateTime() {
    DateTime now = DateTime.now();
    selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour + (amPm == 'PM' ? 12 : 0),
      minute,
    );
    if (selectedDateTime.isBefore(now)) {
      selectedDateTime = selectedDateTime.add(const Duration(days: 1));
    }
    getDay();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? now = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        currentDate: selectedDateTime,
        lastDate: DateTime(2030, 12, 31));

    if (now != null) {
      setState(() {
        selectedDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          selectedDateTime.hour,
          selectedDateTime.minute,
        );
        if (selectedDateTime.isBefore(DateTime.now())) {
          selectedDateTime = selectedDateTime.add(const Duration(days: 1));
        }
        getDay();
      });
    }
  }
}
