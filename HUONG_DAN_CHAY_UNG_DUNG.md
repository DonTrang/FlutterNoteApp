# Hướng Dẫn Chạy Ứng Dụng Quản Lý Ghi Chú

## Tình trạng hiện tại

Ứng dụng đã được tạo hoàn chỉnh với đầy đủ chức năng:
- ✅ Tạo, xem, sửa, xóa ghi chú
- ✅ Tìm kiếm ghi chú
- ✅ Lưu trữ cục bộ với SQLite
- ✅ Giao diện Material Design

## Các cách chạy ứng dụng

### 1. Chạy trên Android Emulator (Khuyến nghị)

**Bước 1:** Khởi động Android Emulator
```bash
flutter emulators --launch Medium_Phone_API_36.0
```

**Bước 2:** Đợi emulator khởi động hoàn toàn (có thể mất 1-2 phút)

**Bước 3:** Kiểm tra thiết bị
```bash
flutter devices
```

**Bước 4:** Chạy ứng dụng
```bash
flutter run
```
Hoặc chọn thiết bị Android khi được hỏi.

### 2. Chạy trên Windows Desktop

**Vấn đề:** Hiện tại thiếu Visual Studio components.

**Giải pháp:** Cài đặt Visual Studio components:

1. Mở **Visual Studio Installer**
2. Chọn **Modify** cho Visual Studio Community 2022
3. Đảm bảo đã chọn workload: **"Desktop development with C++"**
4. Trong phần **Individual components**, đảm bảo có:
   - ✅ MSVC v142 - VS 2019 C++ x64/x86 build tools (hoặc phiên bản mới hơn)
   - ✅ C++ CMake tools for Windows
   - ✅ Windows 10 SDK (hoặc Windows 11 SDK)

5. Click **Modify** để cài đặt
6. Sau khi cài xong, chạy lại:
```bash
flutter doctor
flutter run -d windows
```

### 3. Chạy trên Web (Cần chỉnh sửa code)

**Lưu ý:** SQLite (`sqflite`) không hỗ trợ web. Để chạy trên web, cần:
- Sử dụng `shared_preferences` hoặc `IndexedDB` thay cho SQLite
- Hoặc sử dụng `sqflite_common_ffi` với `sqlite3_flutter_libs`

**Giải pháp tạm thời:** Ứng dụng hiện tại chỉ chạy được trên mobile (Android/iOS) và desktop (Windows/Mac/Linux với Visual Studio).

## Kiểm tra tình trạng

Chạy lệnh sau để kiểm tra:
```bash
flutter doctor -v
```

## Khắc phục lỗi Disk Space (nếu gặp)

Nếu gặp lỗi "not enough space on the disk" khi chạy trên web:

1. Dọn dẹp thư mục temp:
   - Xóa file trong `C:\Users\trang\AppData\Local\Temp\`
   - Hoặc chạy Disk Cleanup trên Windows

2. Dọn dẹp Flutter:
```bash
flutter clean
flutter pub get
```

## Khuyến nghị

**Cách tốt nhất:** Chạy trên Android Emulator vì:
- ✅ SQLite hoạt động tốt nhất trên mobile
- ✅ Không cần cài thêm Visual Studio components
- ✅ Trải nghiệm gần giống thiết bị thật

**Thời gian khởi động emulator:** Thường mất 1-3 phút lần đầu tiên.

## Liên hệ hỗ trợ

Nếu vẫn gặp vấn đề, vui lòng cung cấp:
- Output của `flutter doctor -v`
- Thông báo lỗi cụ thể
- Platform bạn muốn chạy (Android/Windows/Web)

