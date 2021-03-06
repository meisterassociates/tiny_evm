# Tiny EVM

Tiny EVM - test assignment for the Mana project (https://github.com/poanetwork/mana) candidates

# Installation

* Clone repo with submodules (so you can get the shared tests),

```
git clone --recurse-submodules https://github.com/ayrat555/tiny_evm
```

* Run `mix deps.get`

# Description

Your task is to write a simple interpreter that can execute a subset of Ethereum Virual Machine (EVM) operation codes. Your implementation will be checked against official Ethereum tests.

What to do:

1. You take a couple of virtual machine tests from Ethereum Common Tests from us.
2. You read [Ethereum's Yellow Paper](https://ethereum.github.io/yellowpaper/paper.pdf) to understand how Ethereum, EVM and related to your tests operation codes work.
3. You read description of [EVM Tests](http://ethereum-tests.readthedocs.io/en/latest/test_types/vm_tests.html)
4. You implement a simple interpreter and check against tests (only values that we check in tests are remaining gas and acoount's storage after code execution).
5. You send your solution to us.

The main task is to understand how EVM works because in this position you'll be working on much more complex version of EVM.
