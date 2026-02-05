# 双 Token 认证设计

## 1. 设计原则

| 原则 | 说明 |
|------|------|
| 短期 access + 长期 refresh | access_token 频繁使用但有效期短，refresh_token 仅用于刷新 |
| access_token 无状态 | JWT 自包含用户信息，服务端无需查库验证（可选黑名单机制） |
| refresh_token 有状态 | 存储在 device_session 表，支持主动吊销 |
| 设备绑定 | 每个 Token 对绑定唯一设备，防止跨设备盗用 |

---

## 2. Token 配置

| Token | 有效期 | 存储位置 | 用途 |
|-------|--------|----------|------|
| access_token | 2 小时 | 客户端内存/安全存储 | 访问业务接口 |
| refresh_token | 30 天 | 客户端安全存储 + 服务端 DB | 刷新 access_token |

---

## 3. 数据表设计

```sql
-- device_session 表核心字段
session_id          -- 会话唯一标识
user_id             -- 用户标识
device_id           -- 设备标识
access_token        -- JWT 访问令牌
refresh_token       -- 刷新令牌
expires_at          -- access_token 过期时间
refresh_expires_at  -- refresh_token 过期时间
status              -- ACTIVE / LOGGED_OUT
```

---

## 4. 业务流程

### 4.1 登录

```
客户端 → POST /auth/login (email, password, deviceInfo)
服务端 → 验证凭证 → 生成双 Token → 写入 device_session → 返回 Token
```

### 4.2 业务请求

```
客户端 → GET /api/xxx (Header: Authorization: Bearer {access_token})
服务端 → 验证 JWT 签名 + 过期时间 → 返回数据
```

### 4.3 Token 刷新

```
access_token 过期 → 客户端调用 POST /auth/refresh (refreshToken)
服务端 → 验证 refresh_token → 生成新双 Token → 更新 device_session → 返回新 Token
```

### 4.4 退出登录

```
客户端 → POST /auth/logout
服务端 → 更新 device_session.status = LOGGED_OUT
```

---

## 5. 安全策略

| 策略 | 实现 |
|------|------|
| Token 签名 | HS256 / RS256 算法签名，防篡改 |
| HTTPS 传输 | 防止中间人窃取 Token |
| 刷新轮换 | 每次刷新生成新的 refresh_token，旧 Token 失效 |
| 设备数限制 | 同一用户最多 10 台设备同时在线 |
| 主动吊销 | 支持踢出指定设备、修改密码后强制下线 |

---

## 6. JWT Payload 结构

```json
{
  "sub": "user-uuid",
  "sid": "session-uuid",
  "did": "device-uuid",
  "iat": 1706313600,
  "exp": 1706320800
}
```

| 字段 | 说明 |
|------|------|
| sub | 用户 ID |
| sid | 会话 ID（用于关联 device_session） |
| did | 设备 ID |
| iat | 签发时间 |
| exp | 过期时间 |

---

## 7. 异常处理

| 场景 | 响应 | 客户端处理 |
|------|------|------------|
| access_token 过期 | 401 + code: TOKEN_EXPIRED | 调用 /auth/refresh |
| refresh_token 过期 | 401 + code: REFRESH_EXPIRED | 跳转登录页 |
| Token 被吊销 | 401 + code: TOKEN_REVOKED | 跳转登录页 |
| 签名验证失败 | 401 + code: INVALID_TOKEN | 跳转登录页 |

---

## 8. 时序图

```
┌────────┐          ┌────────┐          ┌──────────────┐
│ Client │          │ Server │          │device_session│
└───┬────┘          └───┬────┘          └──────┬───────┘
    │                   │                      │
    │  1. 登录请求       │                      │
    │──────────────────>│                      │
    │                   │  2. 生成双Token       │
    │                   │─────────────────────>│ INSERT
    │  3. 返回Token      │                      │
    │<──────────────────│                      │
    │                   │                      │
    │  4. 业务请求       │                      │
    │  (带access_token) │                      │
    │──────────────────>│                      │
    │  5. 验证JWT        │                      │
    │  6. 返回数据       │                      │
    │<──────────────────│                      │
    │                   │                      │
    │  7. access过期     │                      │
    │  调用refresh       │                      │
    │──────────────────>│                      │
    │                   │  8. 验证refresh      │
    │                   │─────────────────────>│ SELECT
    │                   │  9. 更新Token        │
    │                   │─────────────────────>│ UPDATE
    │  10. 返回新Token   │                      │
    │<──────────────────│                      │
    │                   │                      │
```

---

请求 → 提取 Token → validateSession → 查询 device_session
                                        ↓
                            status=ACTIVE? → 否 → 401 UNAUTHORIZED
                                        ↓ 是
                            refresh_token 过期? → 是 → 401 UNAUTHORIZED
                                        ↓ 否
                                    继续处理请求

**文档结束**
