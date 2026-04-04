#include "flutter_window.h"
#include <optional>

FlutterWindow::FlutterWindow(const flutter::FlutterEngine &engine)
    : engine_(engine) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::Create(const std::wstring &title,
                           const Win32Window::Point &origin,
                           const Win32Window::Size &size) {
  if (!Win32Window::Create(title, origin, size)) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = engine_.CreateViewController(
      frame.right - frame.left, frame.bottom - frame.top);
  if (!flutter_controller_) {
    return false;
  }

  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  return Win32Window::OnCreate();
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }
  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }
  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
