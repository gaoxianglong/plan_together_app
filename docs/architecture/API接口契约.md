# 做计划 APP 接口契约文档

## 文档信息

| 项目 | 内容 |
|------|------|
| **文档名称** | API 接口契约文档 |
| **文档版本** | v1.0 |
| **编写日期** | 2026-01-27 |
| **依据文档** | PRD v2.0、技术约束&规范.md |
| **技术栈** | Flutter + Spring Boot + MySQL |
| **API版本** | v1 |

---

## 目录

1. [全局规范](#1-全局规范)
2. [认证授权](#2-认证授权)
3. [任务管理](#3-任务管理)
4. [视图聚合](#4-视图聚合)
5. [专注模块](#5-专注模块)
6. [用户中心](#6-用户中心)
7. [会员权益](#7-会员权益)
8. [错误码定义](#8-错误码定义)

---

## 1. 全局规范

### 1.1 统一响应结构

所有接口返回统一的 JSON 结构：

```json
{
  "code": 0,
  "message": "success",
  "data": {},
  "traceId": "uuid-string",
  "timestamp": 1706313600000
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| code | int | 业务状态码，0 表示成功，非 0 表示失败 |
| message | string | 响应消息描述 |
| data | object/array/null | 业务数据，成功时返回，失败时可为 null |
| traceId | string | 请求追踪 ID（UUID），用于日志追踪 |
| timestamp | long | 服务端响应时间戳（毫秒） |

### 1.2 字段命名规范

- **请求/响应 JSON 字段**：驼峰命名（camelCase），如 `createdAt`、`userId`
- **URL 路径**：小写 + 连字符（kebab-case），如 `/api/v1/user-profile`
- **查询参数**：驼峰命名（camelCase），如 `?startDate=2026-01-27`

### 1.3 版本控制

- **URL 前缀**：`/api/v1`
- **版本策略**：v1 为当前版本，未来如需升级 API，使用 v2、v3 等

### 1.4 鉴权方式

- **登录接口**：无需鉴权
- **业务接口**：需携带 `Authorization: Bearer {access_token}` 请求头
- **Token 过期**：返回 `401 Unauthorized`，客户端使用 refresh_token 刷新

### 1.5 幂等性要求

- **幂等接口**：创建任务、打卡、支付回调等需携带 `X-Request-Id` 请求头（UUID）
- **幂等实现**：服务端对同一 `X-Request-Id` 的重复请求返回相同结果，不产生副作用
- **幂等窗口**：24 小时（超过 24 小时的相同 Request-Id 可被视为新请求）

### 1.6 分页规范

查询列表接口统一使用以下分页参数：

**请求参数**：
```json
{
  "page": 1,
  "pageSize": 20
}
```

**响应结构**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "list": [],
    "total": 100,
    "page": 1,
    "pageSize": 20,
    "totalPages": 5
  }
}
```

### 1.7 时间格式

- **日期**：`YYYY-MM-DD`（如 `2026-01-27`）
- **日期时间**：ISO 8601 格式 `YYYY-MM-DDTHH:mm:ss.SSSZ`（如 `2026-01-27T10:30:00.000Z`）
- **时间戳**：毫秒级 Unix 时间戳（如 `1706313600000`）

### 1.8 超时与重试

- **客户端超时**：10 秒
- **重试策略**：
  - 幂等接口（GET、PUT、DELETE）：可自动重试 2 次
  - 非幂等接口（POST）：需用户手动重试
- **防抖**：客户端对高频操作（如勾选完成）做 1 秒防抖

---

## 2. 认证授权

### 2.1 邮箱密码登录

**接口描述**：用户通过邮箱和密码登录

**接口路径**：`POST /api/v1/auth/login`

**请求参数**：
```json
{
  "email": "user@example.com",
  "password": "123456",
  "deviceInfo": {
    "deviceId": "uuid-device-id",
    "deviceName": "iPhone 15 Pro",
    "platform": "iOS",
    "osVersion": "17.2",
    "appVersion": "1.0.0"
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 用户邮箱 |
| password | string | 是 | 用户密码 |
| deviceInfo | object | 是 | 设备信息 |
| deviceInfo.deviceId | string | 是 | 设备唯一标识（UUID） |
| deviceInfo.deviceName | string | 是 | 设备名称 |
| deviceInfo.platform | string | 是 | 平台：iOS/Android |
| deviceInfo.osVersion | string | 否 | 系统版本 |
| deviceInfo.appVersion | string | 是 | APP 版本号 |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "userId": "user-uuid",
    "accessToken": "jwt-access-token",
    "refreshToken": "jwt-refresh-token",
    "expiresIn": 7200,
    "userInfo": {
      "nickname": "用户昵称",
      "avatar": "default-avatar-1",
      "ipLocation": "广东 深圳"
    },
    "entitlement": {
      "status": "FREE_TRIAL",
      "trialStartAt": "2026-01-27T00:00:00.000Z",
      "expireAt": "2026-02-27T00:00:00.000Z"
    }
  }
}
```

**错误码**：
- `1001`：邮箱或密码错误
- `1003`：设备数量超出上限（10 台）

**幂等要求**：无（登录接口不幂等，每次返回新 token）

---

### 2.2 用户注册

**接口描述**：用户通过邮箱注册新账号

**接口路径**：`POST /api/v1/auth/register`

**请求头**：
- `X-Request-Id: {uuid}`（幂等）

**请求参数**：
```json
{
  "email": "user@example.com",
  "password": "123456",
  "nickname": "张三",
  "deviceInfo": {
    "deviceId": "uuid-device-id",
    "deviceName": "iPhone 15 Pro",
    "platform": "iOS",
    "osVersion": "17.2",
    "appVersion": "1.0.0"
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 用户邮箱 |
| password | string | 是 | 用户密码，6-32 位 |
| nickname | string | 是 | 用户昵称，1-20 字符 |
| deviceInfo | object | 是 | 设备信息 |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "userId": "user-uuid",
    "accessToken": "jwt-access-token",
    "refreshToken": "jwt-refresh-token",
    "expiresIn": 7200,
    "userInfo": {
      "nickname": "张三",
      "avatar": "default-avatar-1",
      "ipLocation": "广东 深圳"
    },
    "entitlement": {
      "status": "FREE_TRIAL",
      "trialStartAt": "2026-01-27T00:00:00.000Z",
      "expireAt": "2026-02-27T00:00:00.000Z"
    }
  }
}
```

**错误码**：
- `1004`：邮箱已被注册
- `1005`：密码格式不正确（长度不足6位）
- `1006`：昵称包含违规词

**幂等要求**：幂等（同一 Request-Id 重复请求返回相同结果）

---

### 2.3 找回密码

**接口描述**：用户通过邮箱找回密码，账号对应的密码会通过maidenplan@163.com发送给用户

**接口路径**：`POST /api/v1/auth/forgot-password`

**请求参数**：
```json
{
  "email": "user@example.com"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 用户邮箱 |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "message": "密码重置邮件已发送，请查收"
  }
}
```

**错误码**：
- `1007`：邮箱未注册

**说明**：
- 发送包含重置密码链接的邮件到用户邮箱
- 同一邮箱 1 分钟内只能发送 1 次

**幂等要求**：幂等（重复请求不会重复发送邮件，但会刷新有效期）

---

### 2.4 刷新 Token

**接口描述**：使用 refresh_token 刷新 access_token

**接口路径**：`POST /api/v1/auth/refresh`

**请求参数**：
```json
{
  "refreshToken": "jwt-refresh-token"
}
```

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "accessToken": "new-jwt-access-token",
    "refreshToken": "new-jwt-refresh-token",
    "expiresIn": 7200
  }
}
```

**错误码**：
- `401`：refresh_token 无效或过期

---

### 2.5 退出登录

**接口描述**：退出当前设备登录，吊销 token

**接口路径**：`POST /api/v1/auth/logout`

**请求头**：`Authorization: Bearer {access_token}`

**请求参数**：无

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": null
}
```

**幂等要求**：幂等（重复退出返回成功）

---

### 2.6 查询设备列表

**接口描述**：查询当前用户登录的所有设备

**接口路径**：`GET /api/v1/auth/devices`

**请求头**：`Authorization: Bearer {access_token}`

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "currentDevice": {
      "deviceId": "uuid-device-id",
      "deviceName": "iPhone 15 Pro",
      "platform": "iOS",
      "lastLoginIp": "192.168.1.100",
      "lastLoginAt": "2026-01-27T10:00:00.000Z",
      "isCurrent": true
    },
    "otherDevices": [
      {
        "deviceId": "uuid-device-id-2",
        "deviceName": "iPad Pro",
        "platform": "iOS",
        "lastLoginIp": "192.168.1.101",
        "lastLoginAt": "2026-01-26T18:00:00.000Z",
        "isCurrent": false
      }
    ]
  }
}
```

---

### 2.7 踢出指定设备

**接口描述**：退出指定设备登录（仅对非当前设备生效）

**接口路径**：`POST /api/v1/auth/devices/{deviceId}/logout`

**请求头**：`Authorization: Bearer {access_token}`

**路径参数**：
- `deviceId`：设备 ID

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": null
}
```

**错误码**：
- `2001`：不能踢出当前设备
- `2002`：设备不存在

**幂等要求**：幂等（重复踢出返回成功）

---

### 2.8 检查会话状态

**接口描述**：检查当前会话是否有效，供前端定时轮询。如果会话失效（被踢出/退出/过期），前端应跳转到登录页

**接口路径**：`GET /api/v1/auth/session/check`

**请求头**：`Authorization: Bearer {access_token}`

**请求参数**：无

**响应示例**（会话有效）：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "valid": true,
    "userId": "uuid-user-id",
    "deviceId": "uuid-device-id"
  }
}
```

**响应示例**（会话无效）：
```json
{
  "code": 401,
  "message": "未授权",
  "data": null
}
```

**说明**：
- 建议前端每 10 秒轮询一次
- 收到 401 响应时，前端应清除本地 Token 并跳转到登录页
- 此接口不会刷新 Token，仅用于检查会话状态

---

### 2.9 修改密码

**接口描述**：修改当前登录用户的密码

**接口路径**：`POST /api/v1/auth/password`

**请求头**：`Authorization: Bearer {access_token}`

**请求参数**：
```json
{
  "oldPassword": "当前密码",
  "newPassword": "新密码"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| oldPassword | string | 是 | 当前密码 |
| newPassword | string | 是 | 新密码，8-20位，需包含字母和数字 |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "message": "密码修改成功"
  }
}
```

**错误码**：
- `1001`：旧密码错误
- `1005`：新密码格式不正确

**说明**：
- 修改密码后，当前设备保持登录状态
- 其他设备将被强制下线（会话失效）
- 建议前端在修改成功后提示用户其他设备已下线

---

## 3. 任务管理

### 3.1 查询任务列表（按日期）

**接口描述**：查询指定日期的四象限任务列表（自动展开重复任务）

**接口路径**：`GET /api/v1/tasks`

**请求头**：`Authorization: Bearer {access_token}`

**请求参数**：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| date | string | 是 | 日期，格式 YYYY-MM-DD |
| showCompleted | boolean | 否 | 是否显示已完成任务（默认 true） |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "date": "2026-02-10",
    "hasUncheckedTasks": {
      "P0": true,
      "P1": true,
      "P2": false,
      "P3": false
    },
    "tasks": {
      "P0": [
        {
          "id": "task-uuid-1",
          "title": "完成产品需求评审",
          "priority": "P0",
          "status": "INCOMPLETE",
          "date": "2026-02-10",
          "createdAt": "2026-02-10T09:00:00.000Z",
          "completedAt": null,
          "repeatType": "NONE",
          "repeatConfig": null,
          "isRepeatInstance": false,
          "repeatParentId": null,
          "subTasks": []
        }
      ],
      "P1": [
        {
          "id": "abc-def-123_2026-02-10",
          "title": "早起跑步",
          "priority": "P1",
          "status": "INCOMPLETE",
          "date": "2026-02-10",
          "createdAt": "2026-02-08T09:00:00.000Z",
          "completedAt": null,
          "repeatType": "DAILY",
          "repeatConfig": null,
          "isRepeatInstance": true,
          "repeatParentId": "abc-def-123",
          "subTasks": []
        }
      ],
      "P2": [],
      "P3": []
    }
  }
}
```

**说明**：
- `hasUncheckedTasks`：各象限是否有未完成任务（用于日历小圆点展示）
- `tasks`：按象限分组的任务列表，同象限内按创建时间升序排列
- 重复任务采用**虚拟展开**机制：数据库只存 1 条模板，查询时动态计算匹配日期生成虚拟任务
- 虚拟任务的 `id` 格式为 `{模板ID}_{日期}`，实例任务的 `id` 为纯 UUID

**查询内部逻辑**：
1. 查询 `date=D` 的所有实例任务（普通任务 + 已实例化的重复任务）
2. 查询所有重复模板（`repeat_type != NONE`, `is_repeat_instance = 0`, `date <= D`）
3. 对每个模板匹配日期 D（DAILY/WEEKLY/MONTHLY 规则）
4. 排除已有实例的模板，为匹配的模板生成虚拟任务
5. 合并实例任务 + 虚拟任务返回

**前端识别规则**：

| 类型 | ID 格式 | isRepeatInstance | repeatParentId |
|------|---------|-----------------|----------------|
| 普通任务 | `{uuid}` | false | null |
| 重复模板 | `{uuid}` | false | null |
| 虚拟任务（未操作） | `{uuid}_{YYYY-MM-DD}` | true | 模板 UUID |
| 实例任务（已操作） | `{uuid}` | true | 模板 UUID |

**虚拟任务操作规则**：
- 前端对虚拟任务执行操作（完成/编辑/删除）时，直接调用对应接口传虚拟 ID
- 后端自动实例化后执行操作，返回新的实例 ID
- 前端收到响应后用新 ID 替换虚拟 ID

---

### 3.2 创建任务

**接口描述**：创建新任务（支持重复任务）

**接口路径**：`POST /api/v1/tasks`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**请求参数**：
```json
{
  "title": "早起跑步",
  "priority": "P1",
  "date": "2026-02-08",
  "repeatType": "DAILY",
  "repeatConfig": null,
  "repeatEndDate": null
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 是 | 任务标题，1-100 字符 |
| priority | string | 是 | 优先级：P0/P1/P2/P3 |
| date | string | 是 | 归属日期，YYYY-MM-DD，范围：今天-365天 ~ 今天+365天 |
| repeatType | string | 否 | 重复类型：NONE/DAILY/WEEKLY/MONTHLY，默认 NONE |
| repeatConfig | object | 否 | 重复配置（见下方说明） |
| repeatEndDate | string | 否 | 重复结束日期，YYYY-MM-DD，为空表示永久重复 |

**重复配置说明**：

- **DAILY**：无需配置，`repeatConfig` 为 `null`
- **WEEKLY**：
  ```json
  {
    "weekdays": [1, 3, 5]  // 周一、周三、周五（1-7 表示周一到周日）
  }
  ```
- **MONTHLY**：
  ```json
  {
    "dayOfMonth": 1  // 每月 1 号（1-31）
  }
  ```

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "task-uuid",
    "title": "早起跑步",
    "priority": "P1",
    "status": "INCOMPLETE",
    "date": "2026-02-08",
    "repeatType": "DAILY",
    "repeatConfig": null,
    "repeatEndDate": null,
    "createdAt": "2026-02-08T09:00:00.000Z"
  }
}
```

**说明**：
- 重复任务只创建 1 条模板记录，不预生成实例
- 创建后，查询 `date >= 2026-02-08` 的任何日期都能看到该任务（虚拟展开）

**错误码**：
- `3001`：任务标题为空或超长
- `3002`：日期超出范围（今天-365天 ~ 今天+365天）
- `3003`：单日任务数超出上限（50 条）
- `3004`：重复配置格式错误

**幂等要求**：幂等（同一 Request-Id 重复请求返回相同任务）

---

### 3.3 实例化虚拟任务

**接口描述**：将重复任务的虚拟任务持久化为实例（后端操作接口也会自动调用）

**接口路径**：`POST /api/v1/tasks/{taskId}/materialize`

**请求头**：
- `Authorization: Bearer {access_token}`

**路径参数**：
- `taskId`：虚拟任务 ID（格式 `{模板ID}_{YYYY-MM-DD}`）

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "new-instance-uuid",
    "title": "早起跑步",
    "priority": "P1",
    "status": "INCOMPLETE",
    "date": "2026-02-10",
    "repeatType": "DAILY",
    "repeatConfig": null,
    "isRepeatInstance": true,
    "repeatParentId": "abc-def-123",
    "createdAt": "2026-02-10T08:00:00.000Z"
  }
}
```

**说明**：
- 若已有实例存在（已实例化过），直接返回已有实例
- 若 taskId 不是虚拟格式或模板不存在，返回 `3006`
- 其他接口（更新/完成/删除）传入虚拟 ID 时会自动调用本逻辑，无需前端显式调用

**错误码**：
- `3006`：父任务不存在
- `3008`：虚拟任务 ID 格式错误

---

### 3.4 更新任务

**接口描述**：更新任务信息（标题、优先级、日期、重复设置）

**接口路径**：`PUT /api/v1/tasks/{taskId}`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**路径参数**：
- `taskId`：任务 ID（支持模板 ID、虚拟 ID、实例 ID）

**请求参数**：
```json
{
  "title": "早起跑步（更新）",
  "priority": "P0",
  "date": "2026-01-28",
  "repeatType": "WEEKLY",
  "repeatConfig": {
    "weekdays": [1, 3, 5]
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 否 | 任务标题 |
| priority | string | 否 | 优先级 |
| date | string | 否 | 归属日期（修改重复时作为新起始日期） |
| repeatType | string | 否 | 重复类型：NONE/DAILY/WEEKLY/MONTHLY |
| repeatConfig | object | 否 | 重复配置 |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "template-task-uuid",
    "title": "早起跑步（更新）",
    "priority": "P0",
    "date": "2026-02-08",
    "repeatType": "WEEKLY",
    "repeatConfig": {
      "weekdays": [1, 3, 5]
    },
    "updatedAt": "2026-02-08T10:00:00.000Z"
  }
}
```

**不修改重复设置时**（仅修改 title/priority/date）：
- 若 `taskId` 为虚拟 ID，后端自动实例化后更新，响应返回新实例 ID
- 修改实例任务仅影响该实例，不影响模板和其他日期

**修改重复设置时**（传入 `repeatType`）：
- 支持传入任意 ID 类型（模板 ID、虚拟 ID、实例 ID），后端自动定位到模板任务进行修改
- 新重复规则从生效日期开始，只影响未来日期，已完成的历史实例不受影响
- 生效日期规则：传入 `date` 则使用 `date`；未传 `date` 则默认今天
- 生效日期之后的旧实例会被自动清理，按新规则重新生成虚拟任务
- 响应返回的 `id` 是模板任务的 ID
- 支持的变更场景：
  - 非重复 → 重复（DAILY/WEEKLY/MONTHLY）
  - DAILY → WEEKLY / MONTHLY
  - WEEKLY → DAILY / MONTHLY
  - MONTHLY → DAILY / WEEKLY
  - 重复 → 非重复（NONE）

**幂等要求**：幂等

---

### 3.5 删除任务

**接口描述**：删除任务（逻辑删除）

**接口路径**：`DELETE /api/v1/tasks/{taskId}`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**路径参数**：
- `taskId`：任务 ID（支持虚拟 ID）

**请求参数**：
```json
{
  "deleteAll": false
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| deleteAll | boolean | 否 | 是否删除目标日期及之后的所有（默认 false，仅删除当天） |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "deletedCount": 1
  }
}
```

**说明**：
- `deleteAll = false`：仅删除指定日期
  - 若 `taskId` 为虚拟 ID → 创建一条已删除的实例，该日期不再显示
  - 若 `taskId` 为实例 ID → 逻辑删除该实例
  - 若 `taskId` 为普通任务 ID → 逻辑删除该任务
- `deleteAll = true`：删除目标日期及之后的所有（不影响之前）
  - 设置模板的 `repeatEndDate` 为目标日期的前一天
  - 逻辑删除该日期及之后的所有已实例化的任务
  - 之前日期的任务不受影响

**幂等要求**：幂等（重复删除返回成功）

---

### 3.6 完成/反完成任务

**接口描述**：切换任务完成状态

**接口路径**：`POST /api/v1/tasks/{taskId}/toggle-complete`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**路径参数**：
- `taskId`：任务 ID（支持虚拟 ID，自动实例化后完成）

**请求参数**：
```json
{
  "completed": true
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| completed | boolean | 是 | true=完成，false=反完成 |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "task-uuid",
    "status": "COMPLETED",
    "completedAt": "2026-01-27T10:30:00.000Z"
  }
}
```

**错误码**：
- `3005`：父任务存在未完成子任务，无法直接完成

**说明**：
- 若 `taskId` 为虚拟 ID，后端自动实例化后更新状态，响应返回新实例 ID
- 每天的重复任务有**独立的完成状态**：完成 2/10 的任务不影响 2/11 的任务
- 父任务存在子任务时，完成状态由子任务派生

**幂等要求**：幂等

---

### 3.7 创建子任务

**接口描述**：为指定任务创建子任务

**接口路径**：`POST /api/v1/tasks/{taskId}/subtasks`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**路径参数**：
- `taskId`：父任务 ID（支持虚拟 ID，自动实例化父任务）

**请求参数**：
```json
{
  "title": "准备演示文档",
  "repeatType": "NONE",
  "repeatConfig": null
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 是 | 子任务标题，1-50 字符 |
| repeatType | string | 否 | 重复类型，默认继承父任务 |
| repeatConfig | object | 否 | 重复配置，默认继承父任务 |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "subtask-uuid",
    "parentId": "instance-task-uuid",
    "title": "准备演示文档",
    "status": "INCOMPLETE",
    "repeatType": "NONE",
    "createdAt": "2026-01-27T10:00:00.000Z"
  }
}
```

**错误码**：
- `3006`：父任务不存在
- `3007`：子任务数量超出上限（20 条）

**重复任务说明**：
- 若 `taskId` 为虚拟 ID（如 `{templateId}_{date}`），后端自动实例化父任务
- 子任务创建在实例任务上，仅影响当天，不影响其他日期
- 已有模板子任务会自动克隆到实例任务

**幂等要求**：幂等

---

### 3.8 更新子任务

**接口描述**：更新子任务信息

**接口路径**：`PUT /api/v1/subtasks/{subTaskId}`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**路径参数**：
- `subTaskId`：子任务 ID

**请求参数**：
```json
{
  "title": "准备演示文档（更新）",
  "repeatType": "DAILY",
  "date": "2026-02-08"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 否 | 子任务标题 |
| repeatType | string | 否 | 重复类型 |
| date | string | 否 | 操作日期（重复任务按日隔离，格式 YYYY-MM-DD） |

**重复任务说明**：
- 若子任务属于重复模板且传入 `date`，后端自动实例化该日期的父任务并克隆子任务，仅修改当天的副本

**幂等要求**：幂等

---

### 3.9 删除子任务

**接口描述**：删除子任务（逻辑删除）

**接口路径**：`DELETE /api/v1/subtasks/{subTaskId}?date=2026-02-08`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**路径参数**：
- `subTaskId`：子任务 ID

**查询参数**：
- `date`：操作日期（可选，重复任务按日隔离，格式 YYYY-MM-DD）

**重复任务说明**：
- 若子任务属于重复模板且传入 `date`，后端自动实例化该日期的父任务并克隆子任务，仅删除当天的副本

**幂等要求**：幂等

---

### 3.10 完成/反完成子任务

**接口描述**：切换子任务完成状态

**接口路径**：`POST /api/v1/subtasks/{subTaskId}/toggle-complete`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**路径参数**：
- `subTaskId`：子任务 ID

**请求参数**：
```json
{
  "completed": true,
  "date": "2026-02-08"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| completed | boolean | 是 | true=完成，false=反完成 |
| date | string | 否 | 操作日期（重复任务按日隔离，格式 YYYY-MM-DD） |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "instance-subtask-uuid",
    "status": "COMPLETED",
    "completedAt": "2026-02-08T10:30:00.000Z",
    "parentTask": {
      "id": "instance-task-uuid",
      "status": "INCOMPLETE"
    }
  }
}
```

**重复任务说明**：
- 若子任务属于重复模板且传入 `date`，后端自动实例化该日期的父任务并克隆子任务，仅影响当天
- 响应中返回的 `id` 是当天实例副本的 ID
- 响应中包含父任务最新状态

**幂等要求**：幂等

---

### 3.11 打卡

**接口描述**：点击"打卡/完成今日计划"按钮

**接口路径**：`POST /api/v1/check-in`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**请求参数**：
```json
{
  "date": "2026-01-27"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| date | string | 是 | 打卡日期，YYYY-MM-DD |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "date": "2026-01-27",
    "checkedAt": "2026-01-27T10:30:00.000Z",
    "consecutiveDays": 15
  }
}
```

**说明**：
- 打卡成功后连续打卡天数 +1
- 当日重复打卡幂等，不产生副作用

**幂等要求**：幂等（当日重复打卡返回相同结果）

---

## 4. 视图聚合

### 4.1 查询视图任务列表

**接口描述**：查询周/月视图任务列表（待执行/逾期/已完成）

**接口路径**：`GET /api/v1/views/tasks`

**请求头**：`Authorization: Bearer {access_token}`

**请求参数**：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| viewType | string | 是 | 视图类型：WEEK/MONTH |
| statusTab | string | 是 | 状态标签：PENDING/OVERDUE/COMPLETED |
| startDate | string | 是 | 范围起始日期，YYYY-MM-DD |
| endDate | string | 是 | 范围结束日期，YYYY-MM-DD |

**响应示例（待执行）**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "viewType": "WEEK",
    "statusTab": "PENDING",
    "startDate": "2026-01-26",
    "endDate": "2026-02-01",
    "tasksByDate": [
      {
        "date": "2026-01-27",
        "dateLabel": "今天",
        "tasks": [
          {
            "id": "task-uuid",
            "title": "完成需求评审",
            "priority": "P0",
            "status": "INCOMPLETE",
            "date": "2026-01-27",
            "createdAt": "2026-01-27T09:00:00.000Z"
          }
        ]
      },
      {
        "date": "2026-01-28",
        "dateLabel": "明天",
        "tasks": []
      }
    ]
  }
}
```

**响应示例（逾期）**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "statusTab": "OVERDUE",
    "tasksByDate": [
      {
        "date": "2026-01-25",
        "tasks": [
          {
            "id": "task-uuid",
            "title": "紧急任务",
            "priority": "P0",
            "status": "INCOMPLETE",
            "date": "2026-01-25",
            "overdueDays": 2
          }
        ]
      }
    ]
  }
}
```

**排序规则**：
- **待执行**：按归属日期升序 → 同日按优先级 P0→P3 → 同优先级按创建时间升序
- **逾期**：按归属日期升序（日期越早越靠前）→ 同日按优先级 P0→P3 → 同优先级按创建时间升序
- **已完成**：按完成时间降序（最近完成的在前）→ 同日按优先级 P0→P3 → 同优先级按创建时间降序

---

## 5. 专注模块

### 5.1 开始专注

**接口描述**：开始专注倒计时

**接口路径**：`POST /api/v1/focus/start`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**请求参数**：
```json
{
  "durationSeconds": 1500,
  "type": "OTHER"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| durationSeconds | int | 是 | 时长（秒），范围 600 ~ 3600（即 10 ~ 60 分钟） |
| type | string | 是 | 类型：WORK/STUDY/READING/CODING/EXERCISE/MEDITATION/OTHER |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "sessionId": "session-uuid",
    "durationSeconds": 1500,
    "type": "WORK",
    "startAt": "2026-01-27T10:00:00.000Z",
    "expectedEndAt": "2026-01-27T10:25:00.000Z"
  }
}
```

**错误码**：
- `4001`：存在进行中的会话，无法开始新会话

**幂等要求**：幂等

---

### 5.2 结束专注

**接口描述**：结束专注倒计时（自然结束或手动结束）

**接口路径**：`POST /api/v1/focus/{sessionId}/end`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**路径参数**：
- `sessionId`：会话 ID

**请求参数**：
```json
{
  "elapsedSeconds": 1500,
  "endType": "MANUAL"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| elapsedSeconds | int | 是 | 已完成秒数 |
| endType | string | 是 | 结束类型：NATURAL（自然结束）/MANUAL（手动结束） |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "sessionId": "session-uuid",
    "counted": true,
    "countedSeconds": 1500,
    "totalFocusTime": 18000
  }
}
```

| 字段 | 说明 |
|------|------|
| counted | 是否计入总专注时长 |
| countedSeconds | 计入的秒数 |
| totalFocusTime | 累计总专注时长（秒） |

**计入规则**：
- 自然结束：计入全部时长
- 手动结束：
  - `elapsedSeconds / durationSeconds >= 50%`：计入已完成时长
  - `< 50%`：不计入

**幂等要求**：幂等

---

### 5.3 查询总专注时间

**接口描述**：查询用户累计总专注时间

**接口路径**：`GET /api/v1/focus/total-time`

**请求头**：`Authorization: Bearer {access_token}`

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "totalSeconds": 18000,
    "totalHours": 5
  }
}
```

**说明**：
- `totalHours` 为向下取整（如 3700s = 1h）

---

## 6. 用户中心

### 6.1 查询用户信息

**接口描述**：查询当前用户信息

**接口路径**：`GET /api/v1/user/profile`

**请求头**：`Authorization: Bearer {access_token}`

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "userId": "user-uuid",
    "nickname": "张三",
    "avatar": "default-avatar-1",
    "ipLocation": "广东 深圳",
    "consecutiveDays": 15,
    "lastCheckInDate": "2026-01-27",
    "nicknameModifyCount": 1,
    "nicknameNextModifyAt": "2026-02-03T00:00:00.000Z"
  }
}
```

---

### 6.2 更新用户信息

**接口描述**：更新用户昵称或头像

**接口路径**：`PUT /api/v1/user/profile`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**请求参数**：
```json
{
  "nickname": "张三",
  "avatar": "default-avatar-2"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| nickname | string | 否 | 昵称，1-20 字符 |
| avatar | string | 否 | 头像标识（系统预设头像 ID） |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "nickname": "张三",
    "avatar": "default-avatar-2",
    "updatedAt": "2026-01-27T11:00:00.000Z"
  }
}
```

**错误码**：
- `5001`：昵称包含违规词
- `5002`：昵称修改过于频繁（7 天内最多 2 次）

**幂等要求**：幂等

---

## 7. 会员权益

### 7.1 查询权益状态

**接口描述**：查询用户会员权益状态

**接口路径**：`GET /api/v1/entitlement`

**请求头**：`Authorization: Bearer {access_token}`

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "status": "MEMBER_ACTIVE",
    "trialStartAt": "2026-01-01T00:00:00.000Z",
    "expireAt": "2027-01-27T00:00:00.000Z",
    "remainingDays": 365
  }
}
```

| 字段 | 说明 |
|------|------|
| status | 权益状态：NOT_ENTITLED（未激活）/FREE_TRIAL（免费期）/MEMBER_ACTIVE（会员有效）/EXPIRED（已到期） |
| trialStartAt | 免费期起算时间 |
| expireAt | 会员到期时间 |
| remainingDays | 剩余天数 |

---

### 7.2 创建订单

**接口描述**：创建充值订单

**接口路径**：`POST /api/v1/orders`

**请求头**：
- `Authorization: Bearer {access_token}`
- `X-Request-Id: {uuid}`（幂等）

**请求参数**：
```json
{
  "planType": "YEAR",
  "paymentMethod": "WECHAT_PAY"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| planType | string | 是 | 套餐类型：MONTH（月）/QUARTER（季）/YEAR（年） |
| paymentMethod | string | 是 | 支付方式：WECHAT_PAY/ALIPAY |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "orderId": "order-uuid",
    "planType": "YEAR",
    "amount": 10800,
    "paymentMethod": "WECHAT_PAY",
    "paymentParams": {
      "prepay_id": "wx_prepay_id",
      "sign": "wx_sign"
    },
    "createdAt": "2026-01-27T11:00:00.000Z",
    "expireAt": "2026-01-27T11:15:00.000Z"
  }
}
```

| 字段 | 说明 |
|------|------|
| amount | 金额（分） |
| paymentParams | 支付参数（由客户端调起支付 SDK） |
| expireAt | 订单过期时间（15 分钟） |

**幂等要求**：幂等（同一 Request-Id 重复请求返回相同订单）

---

### 7.3 查询订单状态

**接口描述**：查询订单支付状态

**接口路径**：`GET /api/v1/orders/{orderId}`

**请求头**：`Authorization: Bearer {access_token}`

**路径参数**：
- `orderId`：订单 ID

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "orderId": "order-uuid",
    "status": "PAID",
    "paidAt": "2026-01-27T11:05:00.000Z"
  }
}
```

| 字段 | 说明 |
|------|------|
| status | 订单状态：PENDING（待支付）/PAID（已支付）/EXPIRED（已过期）/REFUNDED（已退款） |

---

### 7.4 支付回调（服务端内部接口）

**接口描述**：微信/支付宝支付回调接口（由支付平台调用）

**接口路径**：`POST /api/v1/payment/callback/{provider}`

**路径参数**：
- `provider`：支付渠道，WECHAT/ALIPAY

**请求参数**：由支付平台提供（JSON/XML）

**响应示例**：
```json
{
  "code": "SUCCESS",
  "message": "OK"
}
```

**处理逻辑**：
1. 验签（验证支付平台签名）
2. 幂等校验（同一订单号仅生效一次）
3. 更新订单状态为 PAID
4. 延长用户会员有效期（若当前为会员，在 `expireAt` 基础上顺延；若已过期，从当前时间起算）
5. 返回成功响应

---

## 8. 错误码定义

### 8.1 全局错误码

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未授权（token 无效或过期） |
| 403 | 禁止访问（权限不足） |
| 404 | 资源不存在 |
| 429 | 请求过于频繁（限流） |
| 500 | 服务器内部错误 |

### 8.2 业务错误码

| 错误码 | 模块 | 说明 |
|--------|------|------|
| 1001 | 认证 | 邮箱或密码错误 |
| 1003 | 认证 | 设备数量超出上限（10 台） |
| 1004 | 认证 | 邮箱已被注册 |
| 1005 | 认证 | 密码格式不正确（长度不足6位） |
| 1006 | 认证 | 昵称包含违规词 |
| 1007 | 认证 | 邮箱未注册 |
| 2001 | 设备管理 | 不能踢出当前设备 |
| 2002 | 设备管理 | 设备不存在 |
| 3001 | 任务管理 | 任务标题为空或超长 |
| 3002 | 任务管理 | 日期超出范围 |
| 3003 | 任务管理 | 单日任务数超出上限（50 条） |
| 3004 | 任务管理 | 重复配置格式错误 |
| 3005 | 任务管理 | 父任务存在未完成子任务，无法直接完成 |
| 3006 | 任务管理 | 父任务不存在 |
| 3007 | 任务管理 | 子任务数量超出上限（20 条） |
| 4001 | 专注 | 存在进行中的会话，无法开始新会话 |
| 5001 | 用户中心 | 昵称包含违规词 |
| 5002 | 用户中心 | 昵称修改过于频繁（7 天内最多 2 次） |
| 6001 | 会员 | 订单不存在 |
| 6002 | 会员 | 订单已过期 |
| 6003 | 会员 | 支付失败 |

---

## 附录

### A. 典型交互时序（文字版）

#### A.1 拉取某天四象限任务列表

1. **客户端**：调用 `GET /api/v1/tasks?date=2026-01-27&showCompleted=true`
2. **服务端**：
   - 验证 token 有效性
   - 查询数据库：筛选 `date=2026-01-27 AND deletedAt IS NULL`
   - 按象限分组，同象限内按创建时间升序排列
   - 计算各象限是否有未完成任务（用于小圆点展示）
   - 返回任务列表
3. **客户端**：渲染四象限任务列表 + 日历小圆点

#### A.2 新增任务

1. **客户端**：生成 `X-Request-Id: uuid`
2. **客户端**：调用 `POST /api/v1/tasks` + 请求体
3. **服务端**：
   - 验证 token
   - 幂等校验（检查 Request-Id 是否已处理）
   - 校验字段：标题长度、日期范围、单日任务数上限
   - 创建任务记录
   - 若设置重复，异步生成重复任务副本（最多 365 个）
   - 返回任务信息
4. **客户端**：刷新任务列表

#### A.3 完成任务

1. **客户端**：生成 `X-Request-Id: uuid`，防抖 1 秒
2. **客户端**：调用 `POST /api/v1/tasks/{taskId}/toggle-complete` + `{"completed": true}`
3. **服务端**：
   - 验证 token
   - 幂等校验
   - 检查父任务是否存在子任务
     - 若无子任务：直接标记为完成
     - 若有子任务：检查所有子任务是否已完成，若是则标记父任务为完成，否则返回错误 `3005`
   - 更新 `status=COMPLETED, completedAt=now()`
   - 返回最新状态
4. **客户端**：更新 UI（显示删除线或隐藏）

#### A.4 专注倒计时完成后回写总专注时长

1. **客户端**：倒计时自然结束，调用 `POST /api/v1/focus/{sessionId}/end` + `{"elapsedSeconds": 1500, "endType": "NATURAL"}`
2. **服务端**：
   - 验证 token
   - 幂等校验
   - 查询会话记录
   - 计算是否计入：自然结束 100% 计入
   - 更新用户总专注时长：`totalFocusTime += elapsedSeconds`
   - 返回计入结果 + 最新总时长
3. **客户端**：更新总专注时间展示

#### A.5 权益校验/订阅态

1. **客户端**：调用 `GET /api/v1/entitlement`
2. **服务端**：
   - 验证 token
   - 查询用户权益记录
   - 判断状态：
     - 未激活：`NOT_ENTITLED`
     - 免费期：`now < trialStartAt + 1 month` → `FREE_TRIAL`
     - 会员有效：`now < expireAt` → `MEMBER_ACTIVE`
     - 已到期：`now >= expireAt` → `EXPIRED`
   - 返回权益状态 + 到期时间
3. **客户端**：根据状态显示会员标识或引导充值

#### A.6 多设备登录管理

1. **客户端**：调用 `GET /api/v1/auth/devices`
2. **服务端**：
   - 验证 token
   - 查询用户所有登录设备（基于 token 表）
   - 标记当前设备（通过 token 匹配）
   - 返回当前设备 + 其他设备列表
3. **客户端**：渲染设备列表
4. **用户操作**：点击"退出登录"按钮（非当前设备）
5. **客户端**：调用 `POST /api/v1/auth/devices/{deviceId}/logout`
6. **服务端**：
   - 验证 token
   - 检查是否为当前设备（若是则返回错误 `2001`）
   - 吊销目标设备 token（标记为失效）
   - 返回成功
7. **被踢设备**：下次请求时收到 `401`，自动跳转登录页

---

**文档结束**
