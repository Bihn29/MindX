# Week 2: Metrics & Monitoring Guide

Hướng dẫn truy cập và sử dụng Production Metrics (Azure Application Insights) và Product Metrics (Google Analytics) cho MindX Week 2 Project.

---

## 📊 1. Azure Application Insights (Production Metrics)

### Truy cập Application Insights

1. Đăng nhập vào [Azure Portal](https://portal.azure.com)
2. Tìm resource: **mindx-app-insights**
3. Hoặc truy cập trực tiếp: Application Insights → mindx-app-insights

### Các Metrics chính cần theo dõi

#### **1.1 Live Metrics** (Real-time monitoring)
- **Đường dẫn**: Application Insights → Live Metrics
- **Nội dung**:
  - Incoming Requests per second
  - Outgoing Requests per second  
  - Overall Health
  - Servers online
  - Sample Telemetry (real-time logs)
- **Khi nào dùng**: Monitor real-time khi deploy hoặc test

#### **1.2 Performance**
- **Đường dẫn**: Application Insights → Performance
- **Nội dung**:
  - Average response time per endpoint
  - Request count
  - Failed requests
  - Dependencies performance
- **Metrics quan trọng**:
  - Response time < 1s là tốt
  - P95 response time (95% requests < X ms)
  - Failed request rate < 1%

#### **1.3 Failures**
- **Đường dẫn**: Application Insights → Failures
- **Nội dung**:
  - Failed request count
  - Exception types
  - Failed dependencies
  - Stack traces
- **Hành động**: Click vào exception để xem chi tiết stack trace

#### **1.4 Logs**
- **Đường dẫn**: Application Insights → Logs
- **Query examples**:

```kusto
// All requests in last 24 hours
requests
| where timestamp > ago(24h)
| project timestamp, name, url, resultCode, duration

// Failed requests
requests
| where success == false
| where timestamp > ago(1h)
| project timestamp, name, resultCode, duration

// Exceptions
exceptions
| where timestamp > ago(24h)
| project timestamp, type, outerMessage, innermostMessage

// Average response time by endpoint
requests
| where timestamp > ago(1h)
| summarize avg(duration) by name
| order by avg_duration desc
```

#### **1.5 Alerts**
- **Đường dẫn**: Application Insights → Alerts
- **Alerts đã setup**:
  1. **High Failed Request Rate**: > 5 failed requests in 5 minutes
  2. **High Response Time**: Average response time > 1000ms
  3. **High Exception Rate**: > 3 exceptions in 5 minutes
- **Action Group**: Gửi email thông báo khi alert trigger

---

## 📈 2. Google Analytics (Product Metrics)

### Truy cập Google Analytics

1. Đăng nhập vào [Google Analytics](https://analytics.google.com)
2. Chọn Property: **MindX Test App**
3. Measurement ID: `G-4D36DGJFCX`

### Các Reports chính

#### **2.1 Realtime Report**
- **Đường dẫn**: Reports → Realtime
- **Nội dung**:
  - Users currently active
  - Page views trong 30 phút qua
  - Top pages being viewed
  - Traffic sources
  - Locations
- **Khi nào dùng**: Test tính năng mới, xem user behavior real-time

#### **2.2 User Acquisition**
- **Đường dẫn**: Reports → Acquisition → User acquisition
- **Nội dung**:
  - Nguồn traffic (Direct, Organic Search, Referral, Social)
  - New users vs Returning users
  - Sessions by channel
- **Metrics quan trọng**:
  - Session source/medium
  - First user source
  - User engagement

#### **2.3 Engagement**
- **Đường dẫn**: Reports → Engagement → Pages and screens
- **Nội dung**:
  - Page views per page
  - Average engagement time per page
  - Views per user
- **Pages được track**:
  - `/` - Home page
  - `/about` - About page
  - `/auth/callback` - Auth callback page

#### **2.4 Events**
- **Đường dẫn**: Reports → Engagement → Events
- **Events được track**:
  - `page_view` - Mỗi khi user xem page
  - Custom events (nếu có thêm)
- **Metrics**:
  - Event count
  - Event count per user
  - Total users

#### **2.5 Demographics**
- **Đường dẫn**: Reports → User → Demographics
- **Nội dung**:
  - Countries
  - Cities
  - Languages
  - Devices (Desktop, Mobile, Tablet)
  - Browsers
  - Operating Systems

---

## 🧪 3. Testing Metrics

### Test Application Insights

#### **Test Normal Requests**
```bash
# Health check
curl http://localhost:3000/health

# Get info
curl http://localhost:3000/api/info
```

#### **Test Error Monitoring**
```bash
# Test 500 error
curl http://localhost:3000/api/test/error

# Test slow response (2s delay)
curl http://localhost:3000/api/test/slow

# Test exception
curl http://localhost:3000/api/test/exception
```

**Sau 2-5 phút:**
- Vào Azure Portal → Application Insights → Failures
- Bạn sẽ thấy errors và exceptions
- Check email xem có nhận alert không

#### **Test Performance Monitoring**
```bash
# Gọi nhiều requests liên tục
for i in {1..20}; do curl http://localhost:3000/api/info; done
```

**Kiểm tra:**
- Live Metrics: Xem real-time request rate
- Performance: Xem average response time

---

### Test Google Analytics

#### **Test Page Views**
1. Mở trình duyệt: http://localhost:5173/
2. Navigate qua các pages: Home → About
3. Mở DevTools Console (F12) → thấy logs:
   ```
   ✅ Google Analytics initialized successfully
   📊 GA: Page view tracked - /
   📊 GA: Page view tracked - /about
   ```

#### **Kiểm tra Real-time**
1. Vào Google Analytics → Realtime
2. Bạn sẽ thấy:
   - 1 active user (bạn)
   - Pages đang view
   - Events

#### **Test Custom Events** (Optional)
Thêm vào code để track custom events:
```typescript
import { logEvent } from './services/analytics';

// Track button click
logEvent('Button', 'Click', 'Login Button');

// Track feature usage
logEvent('Feature', 'Use', 'Search');
```

---

## 🔍 4. Troubleshooting

### Application Insights không nhận data

**Kiểm tra:**
1. Connection String đúng trong `.env`
2. Backend đang chạy
3. Đợi 2-5 phút (data có delay)
4. Check console log: `✅ Application Insights initialized successfully`

**Nếu vẫn không thấy:**
```bash
# Kiểm tra biến môi trường
echo $env:APPLICATIONINSIGHTS_CONNECTION_STRING

# Restart backend
cd backend
npm run dev
```

### Google Analytics không track

**Kiểm tra:**
1. Measurement ID đúng trong `.env`
2. File `.env` có prefix `VITE_` cho Vite
3. Frontend đang chạy
4. Check console log: `✅ Google Analytics initialized successfully`

**Nếu vẫn không thấy:**
```bash
# Kiểm tra biến môi trường (trong browser console)
console.log(import.meta.env.VITE_GA_MEASUREMENT_ID)

# Restart frontend
cd frontend
npm run dev
```

---

## 📚 5. Best Practices

### Application Insights

1. **Đặt tên descriptive cho custom telemetry**
2. **Sử dụng Severity levels đúng**: Info, Warning, Error, Critical
3. **Log đủ context**: Request ID, User ID, Operation ID
4. **Set up alerts hợp lý**: Không quá nhạy cảm, không quá lơi lỏng
5. **Monitor dependencies**: Database, external APIs
6. **Review Kusto queries thường xuyên** để phát hiện patterns

### Google Analytics

1. **Track meaningful events**: Login, Purchase, Feature Usage
2. **Sử dụng custom dimensions** cho user segments
3. **Set up Goals và Conversions** cho business metrics
4. **Privacy**: Không track PII (Personal Identifiable Information)
5. **Test trước khi deploy**: Dùng GA debug mode
6. **Regular reports**: Weekly/Monthly để track trends

---

## 📞 6. Support & Resources

### Azure Application Insights
- [Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Kusto Query Language](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/)
- [Best Practices](https://docs.microsoft.com/en-us/azure/azure-monitor/app/best-practices)

### Google Analytics
- [GA4 Documentation](https://support.google.com/analytics/answer/9304153)
- [Event Tracking Guide](https://developers.google.com/analytics/devguides/collection/ga4/events)
- [React GA4 Library](https://github.com/PriceRunner/react-ga4)

---

## ✅ Acceptance Criteria Checklist

- [x] Azure App Insights tích hợp backend
- [x] Application logs, errors, performance metrics visible
- [x] Alerts setup và tested
- [x] Google Analytics tích hợp frontend  
- [x] Page views, sessions, events được track
- [x] Documentation hoàn thành
- [ ] Code committed và pushed to repository

---

**Tác giả**: MindX Week 2 Project  
**Ngày cập nhật**: January 8, 2026  
**Version**: 1.0