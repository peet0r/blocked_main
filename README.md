# blocked_main

A self contained app that displays a difficult to test for main thread block.

## Problem

This application blocks the main thread with a computation heavy operation, the user has a fully frozen screen. When the computation is completed and the main thread is unblocked and the app returns to the normal responsive state (nothing shocking here).

This "unresponsive" state is easy to detect when running/testing the application with a human in the loop. However, when using the provided programmatic testing toolchain this "unresponsive" state does not trigger any issues on performance tests using the `traceAction`,`tracePerformance` or any `TimelineSummary` based diagnostics.

## Steps to reproduce manually

1. `cd flutter_blocked_main_thread`
2. `flutter run -d macos --profile`
3. Open Flutter DevTools debugger & profiler via webpage
4. In the `Performance` tab, turn on the performance overlay
5. Follow the instructions in the app UI
6. Take note of the following behavior:
   1. The main thread gets blocked and UI is "unresponsive"
   2. During this unresponsive time, you can attempt to click the second button N times, but there is no console messages confirming our "unresponsive" state.
   3. Once we see the thread is no longer blocked we see all N messages from our clicking show up.
   4. The performance overlay and performance tab will not report any issues even though the app was frozen for a significant time. The actual time spent rendering the frame that immediately follows the blocking function is within spec so the performance tooling says app is operating within spec.


## Now lets reproduce using flutter tooling...
The test is currently only looking at rendering performance via the `watchPerformance` 

1. `flutter drive --profile --driver=test_driver/block_driver.dart --target=performance_test/block_perf.dart  -d macos`
2. This will dump a performance report to `build/integration_response_data.json`
3. Looking at the render stats you will see the render frame times are within spec. Note: time is reported in milliseconds where noted and micro seconds in the arrays