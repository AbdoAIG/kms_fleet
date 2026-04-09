# Firebase CMake Fix for Windows

If you get a CMake error when building for Windows:

```
CMake Error: cmake_minimum_required VERSION 3.5
Compatibility with CMake < 3.5 has been removed from CMake.
```

## Solution

Delete the old build folder and rebuild:

```bash
cd flutter-app
rmdir /s /q build
flutter clean
flutter pub get
flutter run -d windows
```

## If the error persists

The Firebase C++ SDK extracted in the build folder may have an old CMakeLists.txt.
Edit this file:

```
build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt
```

Change line 17 from:
```cmake
cmake_minimum_required(VERSION 3.5)
```

To:
```cmake
cmake_minimum_required(VERSION 3.5...3.27)
```

Then rebuild:
```bash
flutter run -d windows
```
