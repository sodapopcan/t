#!/usr/bin/env bash

set -euo pipefail

USAGE=$(cat <<'EOF'
x             List all tasks for current list
x Some item   Add task called "Some item" to the current list
x -x "item"   Check off the task containing "item"
x -X "item"   Uncheck the task containing "item"
x -d "item"   Delete task containing "item"
x -S          Sorts the current list
x -p          Purge completed tasks in the current list
x -n          Create a new todo list
x -l          Print all todo lists
x -c list     Make <list> the current list
x -t          Print uncompleted tasks only
x -T          Print completed tasks only
x -s          Print the status for the current list
x -e          Opens the todo file in $EDITOR
EOF
)

if [ -z X_TODO_DIR ]; then
  TODO_DIR="${T_TODO_DIR}"
else
  TODO_DIR="${HOME}/todos"
fi

# Initialize
[ ! -d "${TODO_DIR}" ] && mkdir "${TODO_DIR}"
CURRENT_FILE="${TODO_DIR}/.current"
if [ ! -f "$CURRENT_FILE" ] || [ ! -s "$CURRENT_FILE" ]; then
  echo "todo" > "$CURRENT_FILE"
fi

CURRENT_TODO="${TODO_DIR}/$(cat "$CURRENT_FILE")"

function create_todo_list {
  local todo="${TODO_DIR}/$1"
  touch "$todo"
  echo $1 > "$CURRENT_FILE"
}

function make_current_list {
  if [ -f "$TODO_DIR/$1" ]; then
    echo $1 > "$CURRENT_FILE"
    CURRENT_TODO="${TODO_DIR}/$(cat "$CURRENT_FILE")"
    print_tasks
  else
    echo "Todo list does not exist"
  fi
}

function complete_task {
  sed -i'.bak' -e "/$1/ s/\[ \]/[x]/" "${CURRENT_TODO}"
}

function uncomplete_task {
  sed -i'.bak' -e "/$1/ s/\[\x\]/[ ]/" "${CURRENT_TODO}"
}

function delete_task {
  sed -i'.bak' "/$1/d" "${CURRENT_TODO}"
}

function sort_tasks {
  sort --output="${CURRENT_TODO}" "${CURRENT_TODO}"
}

function purge_completed_tasks {
  sed -i'.bak' "/\[\x\]/d" "${CURRENT_TODO}"
}

function edit_todo_file {
  "$EDITOR" "${CURRENT_TODO}"
}

function print_todo_lists {
  for entry in "${TODO_DIR}"/*; do
    if [ "$entry" = "$CURRENT_TODO" ]; then
      echo '*' $(basename "$entry")
    else
      echo ' ' $(basename "$entry")
    fi
  done
}

function print_tasks {
  cat "${CURRENT_TODO}"
}

function print_uncompleted_tasks {
  cat "${CURRENT_TODO}" | { grep -e '^\[ \]' || true; }
}

function print_completed_tasks {
  cat "${CURRENT_TODO}" | { grep -e '^\[x\]' || true; }
}

function print_status {
  completed=$(print_completed_tasks | wc -l | tr -d ' ')
  all=$(print_tasks | wc -l | tr -d ' ')

  echo "$(cat $CURRENT_FILE): $completed/$all"
}

function print_usage {
  echo "${USAGE}"
}

while getopts 'x:X:d:n:c:SlhepstT' opt; do
  case "$opt" in
    n)
      create_todo_list "${OPTARG}"
      ;;

    c)
      make_current_list "${OPTARG}"
      ;;

    l)
      print_todo_lists
      ;;

    x)
      complete_task "${OPTARG}"
      print_tasks
      ;;

    X)
      uncomplete_task "${OPTARG}"
      print_tasks
      ;;

    d)
      delete_task "${OPTARG}"
      print_tasks
      ;;

    S)
      sort_tasks
      print_tasks
      ;;

    p)
      purge_completed_tasks
      print_tasks
      ;;

    t)
      print_uncompleted_tasks
      ;;

    T)
      print_completed_tasks
      ;;

    s)
      print_status
      ;;

    e)
      edit_todo_file
      ;;

    h)
      print_usage
      ;;
  esac
done

if [ $OPTIND -eq 1 ]; then
  [ ${#@} -gt 0 ] && echo "[ ] $@" >> "${CURRENT_TODO}"
  print_tasks
fi

[ -f "${CURRENT_TODO}.bak" ] && rm "${CURRENT_TODO}.bak"

exit 0
