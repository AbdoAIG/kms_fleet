#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., "flutter run") in order to print
  // log output.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    ::AllocConsole();
    ::_freopen_s(&_stdout, "CONOUT$", "w", stdout);
    ::_freopen_s(&_stderr, "CONOUT$", "w", stderr);
    ::setvbuf(stdout, nullptr, _IONBF, 0);
    ::setvbuf(stderr, nullptr, _IONBF, 0);
  }

  ::SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      ::GetCommandLineArguments();

  project.set_command_line_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"KMS Fleet", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  return EXIT_FAILURE;
}
