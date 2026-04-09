#include "win32_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>

#include "resource.h"

namespace {

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

constexpr const wchar_t kMessageWindowClassName[] =
    L"FLUTTER_RUNNER_WIN32_MESSAGE";

const int kOtpFieldHeight = 6;

HINSTANCE g_hInstance = nullptr;

std::wstring GetModuleName() {
  wchar_t buffer[MAX_PATH];
  if (GetModuleFileName(nullptr, buffer, MAX_PATH) == 0) {
    return L"";
  }
  return std::wstring(buffer);
}

std::wstring GetDesktopHwndClassName() {
  HWND desktop = GetDesktopWindow();
  wchar_t class_name[256] = {0};
  if (GetClassName(desktop, class_name, 256) == 0) {
    return L"";
  }
  return std::wstring(class_name);
}

std::wstring GetMessageWindowClassName() {
  return GetModuleName() + kMessageWindowClassName;
}

HRESULT SetBackdropType(HWND hwnd, int backdrop_type) {
  return DwmSetWindowAttribute(hwnd, DWMWA_SYSTEMBACKDROP_TYPE, &backdrop_type,
                               sizeof(backdrop_type));
}

}

Win32Window::Win32Window() {
  ++window_counter;
}

Win32Window::~Win32Window() {
  Destroy();
}

bool Win32Window::Create(const std::wstring &title, const Point &origin,
                         const Size &size) {
  Destroy();

  const wchar_t *class_name =
      GetDesktopHwndClassName() == kWindowClassName ? kMessageWindowClassName
                                                   : kWindowClassName;

  WNDCLASS window_class{};
  window_class.lpfnWndProc = WndProc;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hIcon =
      LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = class_name;
  RegisterClass(&window_class);

  HMONITOR monitor = MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);

  AdjustWindowRectEx(&window_rect, kWindowStyle, FALSE, kWindowExStyle);

  window_ = CreateWindowEx(
      kWindowExStyle, class_name, title.c_str(), kWindowStyle,
      origin.x, origin.y, size.width, size.height, nullptr, nullptr,
      GetModuleHandle(nullptr), this);

  if (!window_) {
    return false;
  }

  ShowWindow(window_, SW_SHOWNORMAL);
  UpdateWindow(window_);
  return true;
}

void Win32Window::Destroy() {
  if (window_) {
    DestroyWindow(window_);
    window_ = nullptr;
  }
}

void Win32Window::Show() { ShowWindow(window_, SW_SHOWNORMAL); }

void Win32Window::Hide() { ShowWindow(window_, SW_HIDE); }

void Win32Window::SetTitle(const std::wstring &title) {
  SetWindowText(window_, title.c_str());
}

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

bool Win32Window::OnCreate() { return true; }

void Win32Window::OnDestroy() {
  if (quit_on_close_) {
    PostQuitMessage(0);
  }
}

void Win32Window::SetChildContent(HWND content) {
  ::SetParent(content, window_);
  ::MoveWindow(content, 0, 0,
               static_cast<int>(child_content_width_),
               static_cast<int>(child_content_height_), TRUE);
}

RECT Win32Window::GetClientArea() {
  RECT rect;
  GetClientRect(window_, &rect);
  return rect;
}

HWND Win32Window::GetHandle() { return window_; }

void Win32Window::SetSize(const Size &size) {
  SetWindowPos(window_, nullptr, 0, 0, size.width, size.height,
              SWP_NOMOVE | SWP_NOZORDER);
}

LRESULT Win32Window::MessageHandler(HWND hwnd, UINT const message,
                                    WPARAM const wparam,
                                    LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DPICHANGED: {
      auto new_rect = reinterpret_cast<RECT *>(lparam);
      LONG new_width = new_rect->right - new_rect->left;
      LONG new_height = new_rect->bottom - new_rect->top;
      SetWindowPos(hwnd, nullptr, new_rect->left, new_rect->top, new_width,
                   new_height, SWP_NOZORDER | SWP_NOACTIVATE);
      return 0;
    }
    case WM_DESTROY:
      OnDestroy();
      return 0;
    case WM_SIZE: {
      RECT rect = GetClientArea();
      if (child_content_ != nullptr) {
        MoveWindow(child_content_, 0, 0, rect.right - rect.left,
                   rect.bottom - rect.top, TRUE);
      }
      return 0;
    }
    case WM_NCCREATE: {
      auto window_struct = reinterpret_cast<CREATESTRUCT *>(lparam);
      SetWindowLongPtr(hwnd, GWLP_USERDATA,
                       reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));
      auto that = static_cast<Win32Window *>(window_struct->lpCreateParams);
      that->window_ = hwnd;
    }
    return 0;
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}

UINT Win32Window::window_counter_ = 0;

LRESULT CALLBACK Win32Window::WndProc(HWND const window, UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT *>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));
    auto that = static_cast<Win32Window *>(window_struct->lpCreateParams);
    return that->MessageHandler(window, message, wparam, lparam);
  }
  auto *that = reinterpret_cast<Win32Window *>(GetWindowLongPtr(window, GWLP_USERDATA));
  if (that) {
    return that->MessageHandler(window, message, wparam, lparam);
  }
  return DefWindowProc(window, message, wparam, lparam);
}
