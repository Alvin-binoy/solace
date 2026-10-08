import 'package:workmanager/workmanager.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart'; // <-- Added missing import
import '../di/injection.dart';
import 'overdue_checker_service.dart';
import 'notification_service.dart';

// This pragma tells Flutter not to strip this function out during app compilation
// because it is called natively by the OS in the background.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // 1. Re-initialize Flutter bindings for the background isolate
      WidgetsFlutterBinding.ensureInitialized();

      // 2. Re-initialize local notifications and dependency injection
      await NotificationService().init();
      configureDependencies();

      // 3. Handle specific background tasks
      if (task == 'checkOverdueTasks') {
        // FIXED: Using GetIt.I to match the rest of your app perfectly
        final checker = GetIt.I<OverdueCheckerService>();
        await checker.checkNow();
      }

      // Return true to tell the OS the task was successful
      return true;
    } catch (e) {
      // EDGE CASE: If the database is locked or initialization fails,
      // return false so the OS knows to retry it later.
      return false;
    }
  });
}