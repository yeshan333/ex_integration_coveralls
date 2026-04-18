# Release Demo

[English](README.md)

演示 `ex_integration_coveralls` 在 `mix release` 环境下的使用，包括通过 `dep_apps` 进行多应用覆盖率采集。

## 项目结构

```
examples/
├── dep_lib/          # 小型依赖库（覆盖率采集目标）
│   ├── mix.exs
│   └── lib/dep_lib.ex
└── release_demo/     # 主 OTP 应用
    ├── mix.exs       # 依赖 ex_integration_coveralls + dep_lib
    ├── smoke_test.sh # 端到端 HTTP API 冒烟测试
    ├── config/
    └── lib/
```

`release_demo` 通过 `path: "../dep_lib"` 依赖 `dep_lib`。两者打包在同一个 release 中，可以一起进行覆盖率采集。

## 快速开始

```bash
cd examples/release_demo

# 安装依赖
mix deps.get

# 构建 release
MIX_ENV=prod mix release

# 启动 release（后台运行）
_build/prod/rel/release_demo/bin/release_demo daemon

# 运行冒烟测试
bash smoke_test.sh

# 停止 release
_build/prod/rel/release_demo/bin/release_demo stop
```

## HTTP API

### 单应用覆盖率

```bash
# 启动 release_demo 的覆盖率采集
curl -X POST http://localhost:3333/cov/start \
  -H 'Content-Type: application/json' \
  -d '{"app_name": "release_demo"}'

# 获取总覆盖率
curl http://localhost:3333/cov/total/release_demo
```

### 多应用覆盖率（dep_apps）

在一个会话中同时采集 `release_demo` 及其依赖 `dep_lib` 的覆盖率：

```bash
# 启动 release_demo + dep_lib 的覆盖率采集
curl -X POST http://localhost:3333/cov/start \
  -H 'Content-Type: application/json' \
  -d '{"app_name": "release_demo", "dep_apps": ["dep_lib"]}'

# 获取合并后的总覆盖率（查询参数：逗号分隔）
curl http://localhost:3333/cov/total/release_demo?dep_apps=dep_lib

# 获取包含两个应用文件的详细报告
curl http://localhost:3333/cov/report/release_demo?dep_apps=dep_lib
```

### 其他端点

```bash
# 健康检查
curl http://localhost:3333/ping

# Cover 服务状态
curl http://localhost:3333/cov/status
```

## Elixir API（通过远程控制台）

```bash
_build/prod/rel/release_demo/bin/release_demo remote
```

```elixir
# 单应用
ExIntegrationCoveralls.start_app_cov("release_demo")
ExIntegrationCoveralls.get_app_total_cov("release_demo")

# 多应用（dep_apps）
ExIntegrationCoveralls.start_app_cov("release_demo", dep_apps: ["dep_lib"])
ExIntegrationCoveralls.get_app_total_cov("release_demo", dep_apps: ["dep_lib"])
```

## Release 配置说明

### 必须包含源文件

`ex_integration_coveralls` 在运行时读取源文件来计算行级覆盖率。在 `mix release` 中，默认**不包含**源文件——只打包编译后的 `.beam` 文件。

本示例通过 `mix.exs` 中的自定义 release 步骤解决此问题：

```elixir
releases: [
  release_demo: [
    strip_beams: [keep: ["Docs", "Dbgi"]],
    steps: [:assemble, &copy_app_sources/1]
  ]
]

defp copy_app_sources(release) do
  release_lib = Path.join(release.path, "lib")
  for {app, src} <- [{:release_demo, "lib"}, {:dep_lib, "../dep_lib/lib"}] do
    [target] = Path.wildcard(Path.join(release_lib, "#{app}-*"))
    File.cp_r!(src, Path.join(target, "lib"))
  end
  release
end
```

### 必须保留调试信息

`strip_beams: [keep: ["Docs", "Dbgi"]]` 选项保留了 beam 文件中的 `Dbgi` chunk。这是 `ex_integration_coveralls` 在 release 环境中解析编译时源路径所必需的，因为 `module_info(:compile)` 在 strip 后会被移除。

### 配置

端口可通过 `COV_PORT` 环境变量设置（默认：3333）：

```bash
COV_PORT=4000 _build/prod/rel/release_demo/bin/release_demo start
```
