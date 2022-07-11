# blocked_main

A self contained app that displays a difficult to test for main thread block.

## Problem

This application blocks the main thread with a computation heavy opperation, the user has a fully frozen screen. When the computation is completed and the maint thread is unblocked and the app returns to the normal responsive state (nothing shocking here).

This "unresponsive" state is easy to detect when running/testing the application with a human in the loop. However, when using the provided programatic testing toolchain this "unresponsive" state does not trigger any issues on performance tests using the `traceAction`,`tracePerformance` or any `TimelineSummary` based diagnostics.

## Steps to reproduce

1. `cd flutter_blocked_main_thread`
2. `flutter run -d macos --profile`
3. Open Flutter DevTools debugger & profiler via webpage
4. In the `Performance` tab, turn on the performance overlay
5. Follow the instructions in the app UI
6. Take note of the following behavior:
   1. The main thread gets blocked and UI is "unresponsive"
   2. During this unresponsive time, you can attempt to click the second button N times, but there is no console messages confirming our "unresponsive" state.
   3. Once we see the thread is no longer blocked we see all N messages from our clicking show up.