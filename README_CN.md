# ExIntegrationCoveralls

[English](README.md)

[![Coverage Status](https://coveralls.io/repos/github/yeshan333/ex_integration_coveralls/badge.svg?branch=main)](https://coveralls.io/github/yeshan333/ex_integration_coveralls?branch=main) [![hex.pm version](https://img.shields.io/hexpm/v/ex_integration_coveralls.svg)](https://hex.pm/packages/ex_integration_coveralls) [![hex.pm downloads](https://img.shields.io/hexpm/dt/ex_integration_coveralls.svg)](https://hex.pm/packages/ex_integration_coveralls) [![hex.pm license](https://img.shields.io/hexpm/l/ex_integration_coveralls.svg)](https://github.com/yeshan333/ex_integration_coveralls/blog/main/LICENSE)

一个用于运行时系统代码行级覆盖率分析的库。可用于评估集成测试覆盖率。

> 实践案例:
> - [en](https://github.com/yeshan333/explore_ast_app/blob/main/examples/README.md)
> - [zh_hans 中文版](https://github.com/yeshan333/explore_ast_app/blob/main/examples/README_cn.md)

## 运行测试

使用覆盖率数据运行测试：

```shell
mix test --cover --exclude real_cover
```

## 安装

在 `mix.exs` 的依赖列表中添加 `ex_integration_coveralls`：

```elixir
def deps do
  [
    {:ex_integration_coveralls, "~> 0.9.0"}
  ]
end
```

文档地址：[https://hexdocs.pm/ex_integration_coveralls](https://hexdocs.pm/ex_integration_coveralls/readme.html)。

## 快速开始

应用发布并运行后，只需以下三步即可进行运行时覆盖率采集：

- 第 1 步、连接到运行中的节点：

```shell
/path/bin/your_app remote_console
```

- 第 2 步、指定应用启动覆盖率采集：

```shell
ExIntegrationCoveralls.start_app_cov("your_app_name")
```

注意：`your_app_name` 必须存在于 [:application.which_applications](https://www.erlang.org/doc/man/application.html#which_applications-0) 返回的应用列表中。

- 第 3 步、对上述应用进行外部测试，获取运行时覆盖率或将覆盖率数据推送到覆盖率系统。

```shell
ExIntegrationCoveralls.get_app_total_cov("your_app_name")
# 推送覆盖率数据
ExIntegrationCoveralls.post_app_cov_to_ci(url, extends, "your_app_name")
```

注意：应用发布包应包含源代码。ExIntegrationCoveralls 将使用源代码来计算覆盖率统计数据。一般结构如下：

```shell
.
├── bin
│   ├── explore_ast_app
│   ├── explore_ast_app.bat
│   ├── explore_ast_app_rc_exec.sh
│   ├── no_dot_erlang.boot
│   └── start_clean.boot
├── erts-12.1
│   ├── bin
│   ├── doc
│   ├── include
│   ├── info
│   ├── lib
│   └── src
├── lib
│   ├── artificery-0.4.3
│   ├── asn1-5.0.17
│   ├── certifi-2.9.0
│   ├── elixir-1.12.3
│   ├── ex_integration_coveralls-0.4.0 # 运行中的应用
│   ├── explore_ast_app-0.1.0
│   │   ├── consolidated
│   │   ├── ebin
│   │   └── lib                        # 源代码在此
│   └── unicode_util_compat-0.7.0
└── releases
    ├── 0.1.0
    ├── RELEASES
    └── start_erl.data
```

注意：如果使用 [distillery](https://github.com/bitwalker/distillery) 进行 OTP release，配置 `set include_src: true` 即可获得上述结构。但如果使用 Elixir 原生 `mix release`，需要手动处理。参见 [release demo](examples/release_demo) 获取一个包含自定义 release 步骤的完整示例，可自动复制源文件。

## 多应用覆盖率采集 (dep_apps)

在实际项目中，业务逻辑通常分布在多个自定义依赖库中。通过 `dep_apps` 选项，可以在一个覆盖率会话中同时采集主应用及其依赖库的覆盖率：

```elixir
# 启动主应用和依赖库的覆盖率采集
ExIntegrationCoveralls.start_app_cov("my_app", dep_apps: ["shared_lib", "domain_logic"])

# 获取合并后的总覆盖率
ExIntegrationCoveralls.get_app_total_cov("my_app", dep_apps: ["shared_lib", "domain_logic"])

# 将合并的覆盖率数据推送到 CI 系统
ExIntegrationCoveralls.post_app_cov_to_ci(url, extends, "my_app", dep_apps: ["shared_lib"])
```

HTTP API 同样支持 `dep_apps`：

```bash
# 启动覆盖率采集（包含依赖）
curl -X POST http://localhost:3333/cov/start \
  -H 'Content-Type: application/json' \
  -d '{"app_name": "my_app", "dep_apps": ["shared_lib"]}'

# 获取合并后的总覆盖率（逗号分隔的查询参数）
curl http://localhost:3333/cov/total/my_app?dep_apps=shared_lib

# 获取详细的行级覆盖率报告
curl http://localhost:3333/cov/report/my_app?dep_apps=shared_lib
```

## 示例

[`examples/`](examples/) 目录包含一个完整的可运行演示：

| 目录 | 说明 |
|------|------|
| [`examples/release_demo/`](examples/release_demo/) | 主 OTP 应用，演示 `mix release` 与 `ex_integration_coveralls` 的集成。包含 smoke test 脚本，覆盖所有 HTTP 端点。 |
| [`examples/dep_lib/`](examples/dep_lib/) | 一个小型依赖库，被 `release_demo` 使用，演示通过 `dep_apps` 进行多应用覆盖率采集。 |

快速体验：

```bash
cd examples/release_demo
mix deps.get
MIX_ENV=prod mix release
_build/prod/rel/release_demo/bin/release_demo daemon
bash smoke_test.sh
```

详见 [release demo README](examples/release_demo/README_CN.md)。

## 许可证

基于 MIT 许可证分发。详见 [LICENSE](LICENSE)。

## 致谢

感谢以下在 **ExIntegrationCoveralls** 开发过程中使用的优秀资源：

- [Erlang cover](https://www.erlang.org/doc/man/cover.html#description)
- [A brief introduction to BEAM](https://www.erlang.org/blog/a-brief-beam-primer/)
- [excoveralls](https://github.com/parroty/excoveralls)
- [BeamFile - A peek into the BEAM file](https://github.com/hrzndhrn/beam_file)
- [The Elixir AST explorer - ast_ninja](https://github.com/arjan/ast_ninja)
