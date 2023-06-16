import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import '../../progress.dart';

/// A log listener that displays processing progress with logs
class LogListener {
  /// Progress to track
  final ProgressBloc progress;

  /// Display progress
  bool displayProgress;

  bool _progressShown;

  /// Create a new instance
  LogListener(this.progress, {this.displayProgress = false})
      : _progressShown = false {
    progress.stream.listen(onProgress);

    /// Tick additional progress updates
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (progress.isClosed) {
        timer.cancel();
      } else {
        onProgress(progress.state);
      }
    });
  }

  /// Callback on receiving progress state
  void onProgress(ProgressState state) {
    if (displayProgress) {
      clearProgress();
      printProgress(state);
    }
  }

  /// Callback on log records
  void onLogRecord(LogRecord record) {
    String logString =
        '${record.time.toUtc()}/${record.level.name}/${record.loggerName}: ${record.message}';
    if (_progressShown) {
      clearProgress(clearLine: true);
    }
    stdout.writeln(logString);
    //stdout.writeln(logString.padRight(stdout.terminalColumns));
    if (displayProgress && !progress.isClosed) {
      printProgress(progress.state);
    }
  }

  /// Print the progress to stdout
  void printProgress(ProgressState state) {
    double percentComplete = 0.0;
    if (state.messagesTotal != 0) {
      percentComplete = (state.messagesProcessed /
              (state.messagesTotal - state.messagesDropped)) *
          100;
    }
    Duration elapsed = progress.state.elapsed;
    stdout.write(
        "Messages ${state.messagesProcessed.toString().padLeft(10)} / ${(state.messagesTotal - state.messagesDropped).toString().padRight(10)} (${percentComplete.toStringAsFixed(2)}%)    ${elapsed.toString()}"
            .padRight(stdout.terminalColumns));
    _progressShown = true;
  }

  /// Move console to beginning of progress line
  void clearProgress({bool clearLine = false}) {
    stdout.write("\r");
    if (clearLine) {
      stdout.write("".padRight(stdout.terminalColumns));
      stdout.write("\r");
    }
    _progressShown = false;
  }
}
