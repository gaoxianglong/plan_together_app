# JWT 授权服务架构文档

## 1. 技术选型

| 项 | 选型 |
|---|---|
| JWT 库 | io.jsonwebtoken (jjwt) 0.12.6 |
| 签名算法 | HMAC-SHA256(同一个秘钥进行加签/验签动作) |
| 拦截方式 | HandlerInterceptor + WebMvcConfigurer |
| 存储 | device_session 表 |

## 2. Token 结构

**JWT Payload 统一格式：**

| 字段 | 说明 |
|---|---|
| sub | userId |
| sessionId | 会话 UUID |
| deviceId | 设备 UUID |
| type | `access` 或 `refresh` |
| iat | 签发时间 |
| exp | 过期时间 |

**有效期配置（application.properties）：**

- accessToken：`app.jwt.access-token-expiration-hours=2`
- refreshToken：`app.jwt.refresh-token-expiration-days=30`

## 3. 核心流程图

### 3.1 登录签发流程

```
Client                    UserController         UserService            AuthService          DB(device_session)
  |                            |                      |                      |                      |
  |-- POST /login ------------>|                      |                      |                      |
  |                            |-- login(command) ---->|                      |                      |
  |                            |                      |-- generateTokens() ->|                      |
  |                            |                      |<- TokenPair ---------|                      |
  |                            |                      |                      |                      |
  |                            |                      |-- DeviceSession.create()                    |
  |                            |                      |-- save(session) ---------------------------->|
  |                            |                      |                      |                      |
  |<-- {accessToken, refreshToken} -------------------|                      |                      |
```

### 3.2 请求拦截验证流程

```
Client                  AuthInterceptor           AuthService
  |                           |                        |
  |-- GET /api/xxx ---------->|                        |
  |   Authorization: Bearer   |                        |
  |                           |-- validateAccessToken ->|
  |                           |                        |-- 解析JWT签名+过期
  |                           |                        |
  |                     [有效] |<-- Claims -------------|
  |                           |-- set request.attribute("userId","sessionId","deviceId")
  |                           |-- return true (放行)
  |                           |
  |                     [无效] |<-- BusinessException --|
  |<-- 401 未授权 ------------|
```

### 3.3 刷新 Token 流程

```
Client                       AuthService                          DB(device_session)
  |                               |                                      |
  |-- refreshAccessToken(rt) ---->|                                      |
  |                               |-- 1.解析refreshToken JWT             |
  |                               |   [过期/签名无效] -> 抛出 UNAUTHORIZED |
  |                               |                                      |
  |                               |-- 2.findByRefreshToken(rt) --------->|
  |                               |<- DeviceSession --------------------|
  |                               |   [不存在/非ACTIVE] -> 抛出 UNAUTHORIZED
  |                               |                                      |
  |                               |-- 3.生成新accessToken                |
  |                               |-- 4.session.refreshTokens()         |
  |                               |-- update(session) ----------------->|
  |                               |                                      |
  |<-- {newAccessToken, expiresAt}|                                      |
```

### 3.4 退出登录（置 refreshToken 无效）

```
Client                       AuthService                          DB(device_session)
  |                               |                                      |
  |-- invalidateRefreshToken(rt)->|                                      |
  |                               |-- findByRefreshToken(rt) ----------->|
  |                               |<- DeviceSession --------------------|
  |                               |   [不存在] -> 抛出 UNAUTHORIZED       |
  |                               |                                      |
  |                               |-- session.logout()                   |
  |                               |   status -> LOGGED_OUT               |
  |                               |-- update(session) ----------------->|
  |                               |                                      |
  |<-- 成功 ----------------------|                                      |
```

## 4. AuthService 接口清单

| 方法 | 入参 | 出参 | 说明 |
|---|---|---|---|
| `generateTokens` | userId, sessionId, deviceId | TokenPair | 签发双 Token |
| `validateAccessToken` | token | Claims | 验证 accessToken，无效抛 UNAUTHORIZED |
| `invalidateRefreshToken` | refreshToken | void | 将会话置为 LOGGED_OUT |
| `refreshAccessToken` | refreshToken | TokenResult | 用 refreshToken 签发新 accessToken |

## 5. 拦截器配置

**拦截范围：** `/api/**`

**白名单：**

- `/api/v1/user/login`

## 6. 涉及文件

```
com.gxl.plancore
├── common
│   ├── config
│   │   └── WebMvcConfig.java              # 注册拦截器 + 白名单
│   └── interceptor
│       └── AuthInterceptor.java           # 请求拦截验证 accessToken
└── user
    ├── application/service
    │   ├── AuthService.java               # JWT 授权核心服务
    ├── domain
    │   ├── entity/DeviceSession.java      # 会话实体
    │   └── repository/DeviceSessionRepository.java
    └── infrastructure/persistence
        ├── converter/DeviceSessionConverter.java
        ├── mapper/DeviceSessionMapper.java
        ├── po/DeviceSessionPO.java
        └── repository/DeviceSessionRepositoryImpl.java
```
