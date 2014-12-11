library task_scheduler;

import 'dart:async';
import 'task/daily_digest.dart';
import 'task/task.dart';
import 'app.dart';

/**
 * A very simple task scheduler.
 */
class TaskScheduler {
  App app;

  List<Task> tasks = [
  new DailyDigestTask()
  ];

  TaskScheduler(this.app);

  run() {
    tasks.forEach((task) {
      task.app = app; // TODO: This make sense here? It works.
      if (task.runImmediately) {
        task.run();
      } else {
        next() {
          if (task.isRunning) return;

          // TODO: Experimental run at particular time.
          if (task.runAtDailyTime != null) {
            var now = new DateTime.now();
            var other = new DateTime(now.year, now.month, now.day, now.hour, now.minute);

            var runAtTime = task.runAtDailyTime;
            var runAtTimeToToday = new DateTime(now.year, now.month, now.day, runAtTime.hour, runAtTime.minute);
            var diff = now.toUtc().difference(runAtTimeToToday.toUtc());
            // We run our task scheduler every 5 minutes, so let's see if the task's scheduled time is within
            // 5 minutes from now and if it isn't, let's get out of here.
            // TODO: What about edge cases like server restarts?
            if (diff.inMinutes > 5) {
              return;
            }
          }

          if (task.onceADay) {
            var now = new DateTime.now();
            var diff = now.difference(new DateTime(now.year, now.month, now.day + 1, 0, 0, 0));
            if (diff.inMinutes >= 0 || diff.inMinutes < -15) {
              return;
            }
          }

          task.isRunning = true;

          var result = task.run();

          if (result is! Future) {
            task.isRunning = false;
            return;
          }

          result.whenComplete(() {
            task.isRunning = false;
          });
        }

        new Timer.periodic(task.interval, (t) {
          var f = next();
          if (f is Future) {
            f.catchError((e, s) {
              print('Caught severe zone error on Task Scheduler: $e\n\n$s');
            });
          }
        });
      }
    });
  }
}

