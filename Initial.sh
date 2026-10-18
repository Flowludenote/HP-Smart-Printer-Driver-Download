#!/bin/bash
# Электронный журнал студентов (Bash)

# Массивы для хранения данных
declare -a student_ids
declare -a student_names
declare -a student_grades   # оценки хранятся как "id:grade1,grade2,..."

next_id=1001

# ==================== Функции ====================

add_student() {
    local name="$1"
    student_ids+=("$next_id")
    student_names+=("$name")
    student_grades+=("$next_id:")
    echo "Студент \"$name\" добавлен с ID $next_id"
    ((next_id++))
}

find_student_index() {
    local id="$1"
    for i in "${!student_ids[@]}"; do
        if [[ "${student_ids[$i]}" == "$id" ]]; then
            echo "$i"
            return 0
        fi
    done
    echo "-1"
}

add_grade() {
    local id="$1"
    local grade="$2"

    # Проверка диапазона
    if ! [[ "$grade" =~ ^[0-9]+(\.[0-9]+)?$ ]] || (( $(echo "$grade < 0 || $grade > 100" | bc -l) )); then
        echo "Ошибка: оценка должна быть от 0 до 100!"
        return
    fi

    local idx
    idx=$(find_student_index "$id")
    if [[ "$idx" == "-1" ]]; then
        echo "Студент с ID $id не найден!"
        return
    fi

    # Добавляем оценку
    local current="${student_grades[$idx]}"
    if [[ "$current" == *":" && "${current: -1}" == ":" ]]; then
        student_grades[$idx]="${current}${grade}"
    else
        student_grades[$idx]="${current},${grade}"
    fi

    local name="${student_names[$idx]}"
    echo "Оценка $grade добавлена студенту $name"
}

get_average() {
    local grades_str="$1"
    # Убираем "id:"
    local grades_part="${grades_str#*:}"
    if [[ -z "$grades_part" ]]; then
        echo "0.00"
        return
    fi

    local sum=0
    local count=0
    IFS=',' read -ra grades <<< "$grades_part"
    for g in "${grades[@]}"; do
        sum=$(echo "$sum + $g" | bc -l)
        ((count++))
    done

    if (( count == 0 )); then
        echo "0.00"
    else
        echo "scale=2; $sum / $count" | bc -l
    fi
}

print_student_info() {
    local idx="$1"
    local id="${student_ids[$idx]}"
    local name="${student_names[$idx]}"
    local grades_str="${student_grades[$idx]}"
    local avg
    avg=$(get_average "$grades_str")

    local grades_part="${grades_str#*:}"
    local count=0
    if [[ -n "$grades_part" ]]; then
        IFS=',' read -ra gr <<< "$grades_part"
        count=${#gr[@]}
    fi

    printf "ID: %s | Имя: %s | Средний балл: %s | Оценок: %d\n" "$id" "$name" "$avg" "$count"
}

show_all_students() {
    if [[ ${#student_ids[@]} -eq 0 ]]; then
        echo "Список студентов пуст."
        return
    fi
    echo
    echo "=== Список студентов ==="
    for i in "${!student_ids[@]}"; do
        print_student_info "$i"
    done
    echo "========================"
}

show_student_details() {
    local id="$1"
    local idx
    idx=$(find_student_index "$id")
    if [[ "$idx" == "-1" ]]; then
        echo "Студент не найден!"
        return
    fi

    echo
    echo "--- Детали студента ---"
    print_student_info "$idx"

    local grades_str="${student_grades[$idx]}"
    local grades_part="${grades_str#*:}"
    if [[ -n "$grades_part" ]]; then
        echo "Все оценки: $grades_part"
    else
        echo "Оценок пока нет."
    fi
    echo "-----------------------"
}

remove_student() {
    local id="$1"
    local idx
    idx=$(find_student_index "$id")
    if [[ "$idx" == "-1" ]]; then
        echo "Студент с ID $id не найден."
        return
    fi

    unset "student_ids[$idx]"
    unset "student_names[$idx]"
    unset "student_grades[$idx]"

    # Пересобираем массивы без дыр
    student_ids=("${student_ids[@]}")
    student_names=("${student_names[@]}")
    student_grades=("${student_grades[@]}")

    echo "Студент с ID $id удалён."
}

show_statistics() {
    if [[ ${#student_ids[@]} -eq 0 ]]; then
        echo "Нет данных для статистики."
        return
    fi

    local total_avg=0
    local count_with_grades=0
    local max_avg=-1
    local min_avg=101
    local top_student=""
    local bottom_student=""

    for i in "${!student_ids[@]}"; do
        local grades_str="${student_grades[$i]}"
        local grades_part="${grades_str#*:}"
        if [[ -z "$grades_part" ]]; then
            continue
        fi

        local avg
        avg=$(get_average "$grades_str")
        total_avg=$(echo "$total_avg + $avg" | bc -l)
        ((count_with_grades++))

        if (( $(echo "$avg > $max_avg" | bc -l) )); then
            max_avg=$avg
            top_student="${student_names[$i]}"
        fi
        if (( $(echo "$avg < $min_avg" | bc -l) )); then
            min_avg=$avg
            bottom_student="${student_names[$i]}"
        fi
    done

    echo
    echo "=== Статистика ==="
    echo "Всего студентов: ${#student_ids[@]}"
    if (( count_with_grades > 0 )); then
        local group_avg
        group_avg=$(echo "scale=2; $total_avg / $count_with_grades" | bc -l)
        echo "Средний балл по группе: $group_avg"
        echo "Лучший студент: $top_student ($max_avg)"
        echo "Студент с самым низким баллом: $bottom_student ($min_avg)"
    else
        echo "У студентов пока нет оценок."
    fi
    echo "=================="
}

print_menu() {
    echo
    echo "========== Электронный журнал =========="
    echo "1. Добавить студента"
    echo "2. Добавить оценку студенту"
    echo "3. Показать всех студентов"
    echo "4. Показать детали студента"
    echo "5. Удалить студента"
    echo "6. Показать статистику"
    echo "0. Выход"
    echo "========================================"
}

# ==================== Главная программа ====================

echo "Добро пожаловать в простой электронный журнал студентов!"

# Добавляем тестовых студентов
add_student "Иван Петров"
add_student "Анна Сидорова"
add_student "Алексей Козлов"
add_grade 1001 85.5
add_grade 1001 90.0
add_grade 1002 78.0
add_grade 1002 82.5
add_grade 1002 91.0
add_grade 1003 95.0

while true; do
    print_menu
    read -p "Выберите действие: " choice

    case "$choice" in
        1)
            read -p "Введите имя студента: " name
            name=$(echo "$name" | xargs)  # trim
            if [[ -n "$name" ]]; then
                add_student "$name"
            else
                echo "Имя не может быть пустым."
            fi
            ;;
        2)
            read -p "Введите ID студента: " id
            read -p "Введите оценку (0-100): " grade
            if [[ -n "$id" && -n "$grade" ]]; then
                add_grade "$id" "$grade"
            else
                echo "Неверный ввод!"
            fi
            ;;
        3)
            show_all_students
            ;;
        4)
            read -p "Введите ID студента: " id
            if [[ -n "$id" ]]; then
                show_student_details "$id"
            else
                echo "Неверный ввод!"
            fi
            ;;
        5)
            read -p "Введите ID студента для удаления: " id
            if [[ -n "$id" ]]; then
                remove_student "$id"
            else
                echo "Неверный ввод!"
            fi
            ;;
        6)
            show_statistics
            ;;
        0)
            echo "До свидания!"
            exit 0
            ;;
        *)
            echo "Неверный выбор. Попробуйте снова."
            ;;
    esac
done
