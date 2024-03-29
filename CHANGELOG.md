<a name="v0.9.0"></a>
## [v0.9.0](https://github.com/yeshan333/ex_integration_coveralls/compare/v0.8.2...v0.9.0) (2024-03-16)

### Feat

* add http api, support check cover status. close [#11](https://github.com/yeshan333/ex_integration_coveralls/issues/11)


<a name="v0.8.2"></a>
## [v0.8.2](https://github.com/yeshan333/ex_integration_coveralls/compare/0.8.0...v0.8.2) (2023-08-14)

### Feat

* api support async start app cov

### Fix

* read beam file path & change version info read struct
* beam file path search, close [#8](https://github.com/yeshan333/ex_integration_coveralls/issues/8)

<a name="0.8.1"></a>
## [0.8.1](https://github.com/yeshan333/ex_integration_coveralls/compare/0.8.0...0.8.1) (2023-04-18)

### Feat

* support async start app cov ([commit@515ccfd](https://github.com/yeshan333/ex_integration_coveralls/commit/515ccfd9b604ed5e14d83168134a3de598f1408e))

### Fixed

* beam file path search ([#8](https://github.com/yeshan333/ex_integration_coveralls/issues/8))

<a name="0.8.0"></a>
## [0.8.0](https://github.com/yeshan333/ex_integration_coveralls/compare/0.6.0...0.8.0) (2022-07-10)

### Feat

* add a coverage stats GenServer worker ([#5](https://github.com/yeshan333/ex_integration_coveralls/issues/5))
* add a http endpoint to get commit id (User-Domain) ([#3](https://github.com/yeshan333/ex_integration_coveralls/issues/3))

<a name="0.6.0"></a>
## [0.6.0](https://github.com/yeshan333/ex_integration_coveralls/compare/0.5.0...0.6.0) (2022-07-02)

### Feat

* add upload coverage trigger (http endpoint) ([#2](https://github.com/yeshan333/ex_integration_coveralls/issues/2))

<a name="0.5.0"></a>
## [0.5.0](https://github.com/yeshan333/ex_integration_coveralls/compare/0.4.0...0.5.0) (2022-07-01)

### Chore

* **ci:** allow manual triiger github action

### Docs

* add CHANGLOG
* **README:** update coverage badge
* **README:** add ci badges

### Feat

* expose coverage data by http worker ([#1](https://github.com/yeshan333/ex_integration_coveralls/issues/1))

### Release

* 0.5.0


<a name="0.4.0"></a>
## 0.4.0 (2022-06-30)

### Chore

* fix github ci yaml path
* add unittest ci settings
* add deps for publishing ex docs
* update mix.exs

### Docs

* update README

### Feat

* simplify runtime environment coverage collection
* support read coverage path
* add User-Domain Cover CI Service interfact demo     * feat: add User-Domain Cover CI Service interfact demo
* support reset coverage data
* calculate the source code line-level cover data
* elixir wrapper for erlang cover module
* http poster for posting coverage stats to remote ci service
* coverage stats dumps to json
* human-readable coverage output format
* connect files, line coverage information, and source code
* **ExIntegrationCoveralls:** add external entries
* **ex_integration_coveralls.ex:** add get_coverage_report interface

### Refactor

* get cover path export beam directory
* change the path expansion logic
* **ExIntegrationCoveralls.Cover:** reload function -> module_path

### Release

* ex_integration_coveralls[@0](https://github.com/0).4.0
* new version [@0](https://github.com/0).3.0

### Style

* format code
* uniform assert style
* format code

### Test

* add unit test for generate source info func
* fix coverage calc, ignore some side effect cases
* opt cover wrapper test
* first commit
* **ExIntegrationCoveralls:** add unit-tests
* **ExIntegrationCoveralls.CoverTest:** add test for reload function module_path

