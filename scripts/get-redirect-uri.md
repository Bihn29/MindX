# Redirect URI Configuration Guide

## Overview

Khi triển khai ứng dụng lên môi trường dev/production, bạn cần đăng ký Redirect URI với MindX Identity Provider.

## Cách lấy Redirect URI

### 1. Từ Browser Console

1. Mở ứng dụng trên môi trường dev/production
2. Mở Browser Console (F12)
3. Redirect URI sẽ tự động được log ra console khi trang load
4. Copy Redirect URI từ console

### 2. Từ Code

Redirect URI được tính toán tự động dựa trên domain hiện tại:

```
{current_domain}/auth/callback
```

**Ví dụ:**
- Local development: `http://localhost:5173/auth/callback`
- Dev environment: `https://your-dev-domain.com/auth/callback`
- Production: `https://your-production-domain.com/auth/callback`

### 3. Script để lấy Redirect URI

Bạn có thể chạy script sau để lấy Redirect URI:

```bash
# Nếu đã deploy lên dev
# Truy cập: https://your-dev-domain.com
# Mở Console (F12) và xem log

# Hoặc từ code, Redirect URI là:
echo "https://your-dev-domain.com/auth/callback"
```

## Thông tin cần gửi cho Admin

Khi gửi yêu cầu cho admin để thêm Redirect URI vào hệ thống, cung cấp:

1. **Redirect URI:** `https://your-dev-domain.com/auth/callback`
2. **Client ID:** `mindx-onboarding` (đã có sẵn)
3. **Environment:** Dev hoặc Production
4. **Application Name:** Week 1 Full-Stack Application

## Template Email/Message cho Admin

```
Chào Admin,

Tôi cần đăng ký Redirect URI cho ứng dụng Week 1 Full-Stack Application.

Thông tin:
- Client ID: mindx-onboarding
- Redirect URI: https://your-dev-domain.com/auth/callback
- Environment: Dev
- Application: Week 1 Full-Stack Application

Vui lòng thêm Redirect URI này vào hệ thống OpenID Provider.

Cảm ơn!
```

## Kiểm tra sau khi Admin thêm

1. Đảm bảo Redirect URI đã được thêm vào OpenID Provider
2. Test login flow:
   - Click "Login with MindX OpenID"
   - Đăng nhập với test account
   - Kiểm tra redirect về `/auth/callback` thành công
   - Kiểm tra token được lưu và user info hiển thị

## Lưu ý

- Redirect URI phải khớp chính xác với domain đã deploy
- Không có trailing slash
- Phải là HTTPS cho production
- Có thể đăng ký nhiều Redirect URI cho các môi trường khác nhau

