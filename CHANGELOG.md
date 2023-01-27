# CHANGELOG

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