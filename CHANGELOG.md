
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

