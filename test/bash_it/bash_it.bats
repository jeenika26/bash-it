#!/usr/bin/env bats

load ../test_helper
load ../../lib/composure

function local_setup {
  mkdir -p "$BASH_IT"
  lib_directory="$(cd "$(dirname "$0")" && pwd)"
  # Use rsync to copy Bash-it to the temp folder
  # rsync is faster than cp, since we can exclude the large ".git" folder
  rsync -qavrKL -d --delete-excluded --exclude=.git $lib_directory/../.. "$BASH_IT"

  rm -rf "$BASH_IT"/enabled
  rm -rf "$BASH_IT"/aliases/enabled
  rm -rf "$BASH_IT"/completion/enabled
  rm -rf "$BASH_IT"/plugins/enabled

  cp -r "$BASH_IT/test/fixtures/bash_it/aliases" "$BASH_IT"
  cp -r "$BASH_IT/test/fixtures/bash_it/plugins" "$BASH_IT"

  # Don't pollute the user's actual $HOME directory
  # Use a test home directory instead
  export BASH_IT_TEST_CURRENT_HOME="${HOME}"
  export BASH_IT_TEST_HOME="$(cd "${BASH_IT}/.." && pwd)/BASH_IT_TEST_HOME"
  mkdir -p "${BASH_IT_TEST_HOME}"
  export HOME="${BASH_IT_TEST_HOME}"
}

function local_teardown {
  export HOME="${BASH_IT_TEST_CURRENT_HOME}"

  rm -rf "${BASH_IT_TEST_HOME}"

  assert_equal "${BASH_IT_TEST_CURRENT_HOME}" "${HOME}"
}

@test "bash-it: verify that the test fixture is available" {
  assert [ -e "$BASH_IT/aliases/available/a.aliases.bash" ]
  assert [ -e "$BASH_IT/aliases/available/b.aliases.bash" ]
}

@test "bash-it: load aliases in order" {
  mkdir -p $BASH_IT/aliases/enabled
  mkdir -p $BASH_IT/plugins/enabled

  ln -s $BASH_IT/plugins/available/base.plugin.bash $BASH_IT/plugins/enabled/250---base.plugin.bash
  assert [ -L "$BASH_IT/plugins/enabled/250---base.plugin.bash" ]

  ln -s $BASH_IT/aliases/available/a.aliases.bash $BASH_IT/aliases/enabled/150---a.aliases.bash
  assert [ -L "$BASH_IT/aliases/enabled/150---a.aliases.bash" ]
  ln -s $BASH_IT/aliases/available/b.aliases.bash $BASH_IT/aliases/enabled/150---b.aliases.bash
  assert [ -L "$BASH_IT/aliases/enabled/150---b.aliases.bash" ]

  # The `test_alias` alias should not exist
  run alias test_alias &> /dev/null
  assert_failure

  load "$BASH_IT/bash_it.sh"

  run alias test_alias &> /dev/null
  assert_success
  assert_line "0" "alias test_alias='b'"
}

@test "bash-it: load aliases in priority order" {
  mkdir -p $BASH_IT/aliases/enabled
  mkdir -p $BASH_IT/plugins/enabled

  ln -s $BASH_IT/plugins/available/base.plugin.bash $BASH_IT/plugins/enabled/250---base.plugin.bash
  assert [ -L "$BASH_IT/plugins/enabled/250---base.plugin.bash" ]

  ln -s $BASH_IT/aliases/available/a.aliases.bash $BASH_IT/aliases/enabled/175---a.aliases.bash
  assert [ -L "$BASH_IT/aliases/enabled/175---a.aliases.bash" ]
  ln -s $BASH_IT/aliases/available/b.aliases.bash $BASH_IT/aliases/enabled/150---b.aliases.bash
  assert [ -L "$BASH_IT/aliases/enabled/150---b.aliases.bash" ]

  # The `test_alias` alias should not exist
  run alias test_alias &> /dev/null
  assert_failure

  load "$BASH_IT/bash_it.sh"

  run alias test_alias &> /dev/null
  assert_success
  assert_line "0" "alias test_alias='a'"
}

@test "bash-it: load aliases and plugins in priority order" {
  mkdir -p $BASH_IT/aliases/enabled
  mkdir -p $BASH_IT/plugins/enabled

  ln -s $BASH_IT/plugins/available/base.plugin.bash $BASH_IT/plugins/enabled/250---base.plugin.bash
  assert [ -L "$BASH_IT/plugins/enabled/250---base.plugin.bash" ]

  ln -s $BASH_IT/aliases/available/a.aliases.bash $BASH_IT/aliases/enabled/150---a.aliases.bash
  assert [ -L "$BASH_IT/aliases/enabled/150---a.aliases.bash" ]
  ln -s $BASH_IT/aliases/available/b.aliases.bash $BASH_IT/aliases/enabled/150---b.aliases.bash
  assert [ -L "$BASH_IT/aliases/enabled/150---b.aliases.bash" ]
  ln -s $BASH_IT/plugins/available/c.plugin.bash $BASH_IT/plugins/enabled/250---c.plugin.bash
  assert [ -L "$BASH_IT/plugins/enabled/250---c.plugin.bash" ]

  # The `test_alias` alias should not exist
  run alias test_alias &> /dev/null
  assert_failure

  load "$BASH_IT/bash_it.sh"

  run alias test_alias &> /dev/null
  assert_success
  assert_line "0" "alias test_alias='c'"
}

@test "bash-it: load aliases and plugins in priority order, with one alias higher than plugins" {
  mkdir -p $BASH_IT/aliases/enabled
  mkdir -p $BASH_IT/plugins/enabled

  ln -s $BASH_IT/plugins/available/base.plugin.bash $BASH_IT/plugins/enabled/250---base.plugin.bash
  assert [ -L "$BASH_IT/plugins/enabled/250---base.plugin.bash" ]

  ln -s $BASH_IT/aliases/available/a.aliases.bash $BASH_IT/aliases/enabled/350---a.aliases.bash
  assert [ -L "$BASH_IT/aliases/enabled/350---a.aliases.bash" ]
  ln -s $BASH_IT/aliases/available/b.aliases.bash $BASH_IT/aliases/enabled/150---b.aliases.bash
  assert [ -L "$BASH_IT/aliases/enabled/150---b.aliases.bash" ]
  ln -s $BASH_IT/plugins/available/c.plugin.bash $BASH_IT/plugins/enabled/250---c.plugin.bash
  assert [ -L "$BASH_IT/plugins/enabled/250---c.plugin.bash" ]

  # The `test_alias` alias should not exist
  run alias test_alias &> /dev/null
  assert_failure

  load "$BASH_IT/bash_it.sh"

  run alias test_alias &> /dev/null
  assert_success
  # This will be c, loaded from the c plugin, since the individual directories
  # are loaded one by one.
  assert_line "0" "alias test_alias='c'"
}

@test "bash-it: load enabled aliases from new structure, priority-based" {
  mkdir -p $BASH_IT/enabled
  ln -s $BASH_IT/aliases/available/atom.aliases.bash $BASH_IT/enabled/150---atom.aliases.bash
  assert [ -L "$BASH_IT/enabled/150---atom.aliases.bash" ]
  ln -s $BASH_IT/plugins/available/base.plugin.bash $BASH_IT/enabled/250---base.plugin.bash
  assert [ -L "$BASH_IT/enabled/250---base.plugin.bash" ]

  # The `ah` alias should not exist
  run alias ah &> /dev/null
  assert_failure

  load "$BASH_IT/bash_it.sh"

  run alias ah &> /dev/null
  assert_success
}

@test "bash-it: load enabled aliases from old structure, priority-based" {
  mkdir -p $BASH_IT/aliases/enabled
  mkdir -p $BASH_IT/plugins/enabled
  ln -s $BASH_IT/aliases/available/atom.aliases.bash $BASH_IT/aliases/enabled/150---atom.aliases.bash
  assert [ -L "$BASH_IT/aliases/enabled/150---atom.aliases.bash" ]
  ln -s $BASH_IT/plugins/available/base.plugin.bash $BASH_IT/plugins/enabled/250---base.plugin.bash
  assert [ -L "$BASH_IT/plugins/enabled/250---base.plugin.bash" ]

  # The `ah` alias should not exist
  run alias ah &> /dev/null
  assert_failure

  load "$BASH_IT/bash_it.sh"

  run alias ah &> /dev/null
  assert_success
}

@test "bash-it: load enabled aliases from old structure, without priorities" {
  mkdir -p $BASH_IT/aliases/enabled
  mkdir -p $BASH_IT/plugins/enabled
  ln -s $BASH_IT/aliases/available/atom.aliases.bash $BASH_IT/aliases/enabled/atom.aliases.bash
  assert [ -L "$BASH_IT/aliases/enabled/atom.aliases.bash" ]
  ln -s $BASH_IT/plugins/available/base.plugin.bash $BASH_IT/plugins/enabled/base.plugin.bash
  assert [ -L "$BASH_IT/plugins/enabled/base.plugin.bash" ]

  # The `ah` alias should not exist
  run alias ah &> /dev/null
  assert_failure

  load "$BASH_IT/bash_it.sh"

  run alias ah &> /dev/null
  assert_success
}
