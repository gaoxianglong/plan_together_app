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

**接口路径**：`POST /api/v1/user/login`

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

**接口路径**：`POST /api/v1/user/register`

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

**接口路径**：`POST /api/v1/user/forgot-password`

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

**接口路径**：`POST /api/v1/user/refreshAccessToken`

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

**接口路径**：`POST /api/v1/user/logout`

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

**接口路径**：`GET /api/v1/user/devices`

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

**接口路径**：`POST /api/v1/user/devices/{deviceId}/logout`

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

**接口路径**：`GET /api/v1/user/session/check`

**请求头**：无

**请求参数**：无
{
    "refreshToken":"123"
}

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

**接口路径**：`POST /api/v1/user/password`

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

**接口描述**：查询指定日期或多个日期的四象限任务列表（自动展开重复任务）

**接口路径**：`GET /api/v1/tasks`

**请求头**：`Authorization: Bearer {access_token}`

**请求参数**：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| date | string | 否* | 单个日期，格式 YYYY-MM-DD。与 dates 二选一 |
| dates | string | 否* | 多个日期，逗号分隔，如 `2026-02-10,2026-02-11,2026-02-12`。与 date 二选一 |
| showCompleted | boolean | 否 | 是否显示已完成任务（默认 true） |

*注：`date` 与 `dates` 必填其一。传 `dates` 时支持多日期查询；传 `date` 时保持单日期兼容。

**请求示例**：
```
# 单日期（兼容旧版）
GET /api/v1/tasks?date=2026-02-10&showCompleted=true

# 多日期
GET /api/v1/tasks?dates=2026-02-10,2026-02-11,2026-02-12&showCompleted=true
```

**响应示例（单日期）**：
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
          "completedAt": null
        }
      ],
      "P1": [],
      "P2": [],
      "P3": []
    }
  }
}
```

**响应示例（多日期）**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "dataByDate": {
      "2026-02-10": {
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
              "completedAt": null
            }
          ],
          "P1": [],
          "P2": [],
          "P3": []
        }
      },
      "2026-02-11": {
        "hasUncheckedTasks": { "P0": false, "P1": false, "P2": false, "P3": false },
        "tasks": { "P0": [], "P1": [], "P2": [], "P3": [] }
      }
    }
  }
}
```

**说明**：
- 单日期：返回 `date`、`hasUncheckedTasks`、`tasks`，与旧版兼容
- 多日期：返回 `dataByDate`，key 为日期字符串，value 为当日 `hasUncheckedTasks` 与 `tasks`
- `hasUncheckedTasks`：各象限是否有未完成任务（用于日历小圆点展示）
- `tasks`：按象限分组的任务列表，同象限内按创建时间升序排列

---

### 3.2 创建任务

**接口描述**：创建新任务（支持重复任务）

**接口路径**：`POST /api/v1/tasks`

**请求头**：`Authorization: Bearer {access_token}`

**请求参数**：

示例：
```json
{
  "title": "早起跑步",
  "priority": "P1",
  "date": "2026-02-08"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 是 | 任务标题，1-100 字符 |
| priority | string | 是 | 优先级：P0/P1/P2/P3 |
| date | string | 是 | 归属日期，YYYY-MM-DD，范围：今天-365天 ~ 今天+365天 |

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
    "createdAt": "2026-02-08T09:00:00.000Z"
  }
}
```

**错误码**：
- `3001`：任务标题为空或超长
- `3002`：日期超出范围（今天-365天 ~ 今天+365天）
- `3003`：单日任务数超出上限（50 条）

**说明**：任务名称允许重复，不做幂等限制

---

### 3.4 更新任务

**接口描述**：更新任务信息（标题、优先级、日期）

**接口路径**：`PUT /api/v1/tasks/{taskId}`

**请求头**：`Authorization: Bearer {access_token}`

**路径参数**：
- `taskId`：任务 ID

**请求参数**：

示例1 - 非重复任务更新：
```json
{
  "title": "完成报告（更新）",
  "priority": "P0",
  "date": "2026-02-10"
}
```


| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 否 | 任务标题 |
| priority | string | 否 | 优先级 |
| date | string | 否 | 归属日期（仅非重复任务使用） |

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "task-uuid",
    "title": "早起跑步（更新）",
    "priority": "P0",
    "date": "2026-02-08",
    "updatedAt": "2026-02-08T10:00:00.000Z"
  }
}
```
---

### 3.5 删除任务

**接口描述**：删除任务（逻辑删除）

**接口路径**：`DELETE /api/v1/tasks/{taskId}`

**请求头**：
- `Authorization: Bearer {access_token}`

**路径参数**：
- `taskId`：任务 ID


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
**幂等要求**：幂等（重复删除返回成功）

---

### 3.6 完成/反完成任务

**接口描述**：切换任务完成状态

**接口路径**：`POST /api/v1/tasks/{taskId}/toggle-complete`

**请求头**：
- `Authorization: Bearer {access_token}`

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

**错误码**
TASK_NOT_FOUND(3009, "任务不存在");
```

---

### 3.7 打卡

**接口描述**：点击"打卡/完成今日计划"按钮

**接口路径**：`POST /api/v1/check-in`

**请求头**：
- `Authorization: Bearer {access_token}`

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

**连续天数计算规则**：
- 首次打卡 → `consecutiveDays = 1`
- 前一天有打卡记录 → `consecutiveDays = 上次连续天数 + 1`
- 前一天无打卡记录（断签） → `consecutiveDays = 1`

---

### 3.8 查询打卡连续天数

**接口描述**：查询当前用户的打卡连续天数

**接口路径**：`GET /api/v1/check-in/streak`

**请求头**：
- `Authorization: Bearer {access_token}`

**响应示例**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "consecutiveDays": 15,
    "lastCheckInDate": "2026-02-12"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| consecutiveDays | int | 当前连续打卡天数。如果连续性已断（最近打卡日不是今天或昨天），返回 0 |
| lastCheckInDate | string | 最近一次打卡日期，YYYY-MM-DD。无打卡记录时为 null |

**说明**：
- 最近打卡日是今天 → 返回当次记录的连续天数
- 最近打卡日是昨天 → 返回该记录的连续天数（连续性未断，今天还未打卡）
- 最近打卡日早于昨天 → 连续性已断，返回 `consecutiveDays = 0`
- 无打卡记录 → 返回 `consecutiveDays = 0`，`lastCheckInDate = null`

---

## 4. 视图聚合

### 4.1 任务数据统计视图

**接口描述**：按"周"或"月"维度查询任务完成统计概览及对应任务列表，支持按优先级筛选

**接口路径**：`GET /api/v1/tasks/stats`

**请求头**：`Authorization: Bearer {access_token}`

**请求参数**：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| dimension | string | 是 | 查询维度：WEEK / MONTH |
| date | string | 是 | 基准日期，YYYY-MM-DD，用于确定所属周或月 |
| priorities | string | 否 | 优先级筛选，逗号分隔，如 `P0,P1`。不传或为空则查询全部优先级 |

**请求示例**：
```
GET /api/v1/tasks/stats?dimension=WEEK&date=2026-02-12&priorities=P0,P1
```

**响应示例（周维度）**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "dimension": "WEEK",
    "startDate": "2026-02-09",
    "endDate": "2026-02-15",
    "totalCompleted": 13,
    "totalTasks": 20,
    "totalCompletionRate": 65.0,
    "chartData": [
      {
        "label": "2026-02-09",
        "completed": 3,
        "incomplete": 1,
        "total": 4,
        "completionRate": 75.0
      },
      {
        "label": "2026-02-10",
        "completed": 2,
        "incomplete": 2,
        "total": 4,
        "completionRate": 50.0
      }
    ],
    "completedTasks": [
      {
        "id": "task-uuid-1",
        "title": "完成报告",
        "priority": "P0",
        "status": "COMPLETED",
        "date": "2026-02-09",
        "createdAt": "2026-02-09T09:00:00.000Z",
        "completedAt": "2026-02-09T15:00:00.000Z"
      }
    ],
    "incompleteTasks": [
      {
        "id": "task-uuid-2",
        "title": "代码评审",
        "priority": "P1",
        "status": "INCOMPLETE",
        "date": "2026-02-10",
        "createdAt": "2026-02-10T09:00:00.000Z",
        "completedAt": null
      }
    ]
  }
}
```

**响应示例（月维度）**：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "dimension": "MONTH",
    "startDate": "2026-02-01",
    "endDate": "2026-02-28",
    "totalCompleted": 45,
    "totalTasks": 80,
    "totalCompletionRate": 56.25,
    "chartData": [
      {
        "label": "第1周",
        "completed": 10,
        "incomplete": 5,
        "total": 15,
        "completionRate": 66.67
      },
      {
        "label": "第2周",
        "completed": 12,
        "incomplete": 8,
        "total": 20,
        "completionRate": 60.0
      },
      {
        "label": "第3周",
        "completed": 15,
        "incomplete": 5,
        "total": 20,
        "completionRate": 75.0
      },
      {
        "label": "第4周",
        "completed": 8,
        "incomplete": 17,
        "total": 25,
        "completionRate": 32.0
      }
    ],
    "completedTasks": [...],
    "incompleteTasks": [...]
  }
}
```

**字段说明**：

| 字段 | 类型 | 说明 |
|------|------|------|
| dimension | string | 查询维度 WEEK / MONTH |
| startDate | string | 时间区间起始日期 |
| endDate | string | 时间区间结束日期 |
| totalCompleted | int | 区间内已完成任务总数 |
| totalTasks | int | 区间内任务总数 |
| totalCompletionRate | double | 区间内总完成率（百分比，保留2位小数） |
| chartData | array | 图表数据列表 |
| chartData[].label | string | 时间标签（周维度为日期，月维度为"第N周"） |
| chartData[].completed | int | 已完成任务数 |
| chartData[].incomplete | int | 未完成任务数 |
| chartData[].total | int | 任务总数 |
| chartData[].completionRate | double | 完成率（百分比，保留2位小数） |
| completedTasks | array | 已完成任务列表 |
| incompleteTasks | array | 未完成任务列表 |

**周维度规则**：
- 以 ISO 标准周（周一 ~ 周日）为周期
- chartData 返回 7 条记录，每天一条
- label 为日期字符串（YYYY-MM-DD）

**月维度规则**：
- 以自然月（1日 ~ 月末）为周期
- chartData 按周分组：第1周(1-7日)、第2周(8-14日)、第3周(15-21日)、第4周(22-28日)、第5周(29日-月末，如有)
- label 为"第N周"

**优先级筛选**：
- 默认查看全部优先级的任务
- 可传 `priorities=P0` 仅看 P0，或 `priorities=P0,P2` 看 P0 和 P2
- 筛选同时影响统计数据和任务列表

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

**文档结束**
