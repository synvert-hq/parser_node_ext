# CHANGELOG

## 1.4.2 (2024-07-17)

* Rename `fullname` to `full_name`

## 1.4.1 (2024-07-17)

* Add `fullname` to `module` and `class`

## 1.4.0 (2024-07-16)

* Require `parser_node_ext/parent_node_ext` back

## 1.3.2 (2024-04-18)

* Remove `hash_pair` and `hash_value` methods

## 1.3.1 (2024-04-18)

* Remove `.key?` method

## 1.3.0 (2024-04-07)

* Add github actions
* Remove `siblings` method
* Abstract `parser_node_ext/parent_node_ext`

## 1.2.2 (2024-02-10)

* Remove `to_hash` extend

## 1.2.1 (2023-10-01)

* Do not handle `irange` and `erange` in `to_value`

## 1.2.0 (2023-06-10)

* Separate `kwsplats` from hash `pairs`

## 1.1.3 (2023-06-08)

* `node_type` instead of `type` in `to_hash` output

## 1.1.1 (2023-05-19)

* Remove rbs

## 1.1.0 (2023-05-15)

* hash `xxx_value` returns the node rather than the value
* Support `xxx_pair` for `hash` node

## 1.0.0 (2023-02-12)

* Support almost all of nodes

## 0.11.0 (2023-02-12)

* Support `self` node

## 0.10.0 (2023-02-01)

* Support `erange` and `irange` nodes

## 0.9.1 (2023-02-01)

* Fix `module` node `body` method

## 0.9.0 (2023-02-01)

* Support pattern match nodes, `case_match`, `in_pattern`, `hash_pattern`, `array_pattern`, `find_pattern`, `match_pattern`, `match_pattern_p`, `match_var`, `match_as`, `pin`, `match_rest`, `if_guard` and `unless_guard`

## 0.8.0 (2023-01-30)

* Support `numblock` node

## 0.7.0 (2023-01-28)

* Support `elements` for `array` node
* Support `forward_args`

## 0.6.1 (2023-01-21)

* Fix typo

## 0.6.0 (2023-01-06)

* Support `value` for `float`, `int`, `str` and `sym` nodes
* Support `if` node
* Support `case`/`when` node
* Truly dynamically define methods based on const `TYPE_CHILDREN`

## 0.5.1 (2022-12-26)

* hash node pairs should return an array of pair nodes

## 0.5.0 (2022-12-25)

* Add primitive types

## 0.4.1 (2022-10-21)

* Update error message

## 0.4.0 (2022-07-07)

* Raise `MethodNotSupported` error

## 0.3.0 (2022-07-04)

* Add `Node#to_hash`

## 0.2.0 (2022-06-27)

* Add `Node#to_value`
* Add `Node#to_source`
* Support `xxx_value` and `xxx_source` for `hash` node

## 0.1.0 (2022-06-26)

* Abstract from synvert-core
