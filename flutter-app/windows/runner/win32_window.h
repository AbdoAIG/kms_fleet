#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height) : width(width), height(height) {}
  };

  Win32Window();
  ~Win32Window();

  bool Create(const std::wstring &title, const Point &origin, const Size &size);

  void Show();
  void Hide();
  void SetTitle(const std::wstring &title);
  void SetQuitOnClose(bool quit_on_close);

  RECT GetClientArea();

  HWND GetHandle();

  virtual void SetChildContent(HWND content);
  virtual void SetSize(const Size &size);

 protected:
  virtual bool OnCreate();
  virtual void OnDestroy();

 private:
  HWND window_ = nullptr;
  HWND child_content_ = nullptr;
  bool quit_on_close_ = false;

  static UINT window_counter_;
  static LRESULT CALLBACK WndProc(HWND const window, UINT const message,
                                  WPARAM const wparam, LPARAM const lparam);

  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept;

  RECT content_rect_;
  RECT frame_rect_;
};

#endif
