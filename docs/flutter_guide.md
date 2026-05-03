# Hướng dẫn Làm quen với Flutter cho Người mới

Tài liệu này cung cấp các bước cơ bản để bắt đầu phát triển ứng dụng di động bằng Flutter, từ khởi tạo dự án đến cài đặt thư viện và chạy ứng dụng.

---

## 1. Kiểm tra Môi trường (Flutter Doctor)
Trước khi bắt đầu, hãy mở terminal và chạy lệnh sau để đảm bảo máy tính đã cài đặt đầy đủ Flutter SDK, Android Studio hoặc VS Code:

```bash
flutter doctor
```
*Lưu ý: Nếu có dấu [X], hãy làm theo hướng dẫn của Flutter để khắc phục.*

---

## 2. Tạo một Dự án Mới (Create App)
Để tạo một dự án Flutter mới từ terminal, hãy di chuyển đến thư mục bạn muốn lưu dự án và chạy:

```bash
flutter create my_awesome_app
```
Sau đó vào thư mục dự án:
```bash
cd my_awesome_app
```

---

## 3. Cài đặt Thư viện (Add Packages)
Flutter sử dụng trang [pub.dev](https://pub.dev) để quản lý các thư viện (packages). Có hai cách để thêm thư viện vào dự án:

### Cách 1: Sử dụng Terminal (Khuyên dùng)
Chạy lệnh sau để Flutter tự động tìm phiên bản phù hợp và thêm vào file `pubspec.yaml`:
```bash
flutter pub add dio provider google_fonts
```

### Cách 2: Sửa trực tiếp file `pubspec.yaml`
Mở file `pubspec.yaml`, tìm mục `dependencies` và thêm tên thư viện:
```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.3.3
  provider: ^6.0.5
```
Sau đó chạy lệnh để tải thư viện về:
```bash
flutter pub get
```

---

## 4. Chạy ứng dụng (Run App)

### Bước 1: Kết nối thiết bị
- **Android Emulator**: Mở từ Android Studio (Device Manager).
- **iOS Simulator**: Mở bằng lệnh `open -a Simulator` (chỉ trên macOS).
- **Thiết bị thật**: Kết nối qua USB và bật "USB Debugging".

Kiểm tra danh sách thiết bị đang kết nối:
```bash
flutter devices
```

### Bước 2: Chạy
Chạy ứng dụng ở chế độ Debug (hỗ trợ Hot Reload):
```bash
flutter run
```

---

## 5. Các phím tắt quan trọng khi phát triển
Trong khi ứng dụng đang chạy qua terminal:
- **r**: **Hot Reload** (Cập nhật giao diện ngay lập tức - cực nhanh).
- **R**: **Hot Restart** (Khởi động lại ứng dụng, reset trạng thái).
- **q**: Thoát ứng dụng.

---

## 6. Cấu trúc thư mục Flutter cơ bản
- **lib/**: Nơi chứa toàn bộ mã nguồn Dart của bạn (Quan trọng nhất).
- **assets/**: Nơi chứa ảnh, font chữ (cần khai báo trong pubspec.yaml).
- **pubspec.yaml**: Nơi quản lý thư viện và cấu hình dự án.
- **android/ & ios/**: Chứa mã nguồn đặc thù cho từng nền tảng.

---

## 7. Build ứng dụng (Production)
Khi bạn đã sẵn sàng để phát hành ứng dụng, bạn cần build ở chế độ `release`. Chế độ này sẽ tối ưu hóa hiệu suất và giảm kích thước file.

### Build Android
- **Tạo file APK** (Để cài đặt trực tiếp lên điện thoại):
  ```bash
  flutter build apk --release
  ```
  *File xuất ra tại: `build/app/outputs/flutter-apk/app-release.apk`*

- **Tạo file App Bundle** (Để upload lên Google Play Store):
  ```bash
  flutter build appbundle
  ```

### Build iOS (Chỉ trên macOS)
- **Tạo file IPA**:
  ```bash
  flutter build ios --release
  ```
  Sau đó mở `ios/Runner.xcworkspace` trong Xcode để tiến hành lưu trữ (Archive) và tải lên App Store.

### Lưu ý khi Build:
- Hãy chắc chắn bạn đã thay đổi **App Name** và **Bundle ID** trong file cấu hình Android/iOS trước khi build chính thức.
- Chạy `flutter clean` trước khi build bản phát hành để xóa các file rác cũ:
  ```bash
  flutter clean
  flutter pub get
  ```

---
*Chúc bạn có những trải nghiệm tuyệt vời với Flutter!*
