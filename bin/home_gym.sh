#!/bin/bash
# home_gym.sh - Comprehensive Home Workout Tracker
# No equipment needed - bodyweight exercises only!

set -o pipefail

# Configuration
readonly DATA_DIR="$HOME/.home_gym"
readonly HISTORY_FILE="$DATA_DIR/workout_history.csv"
readonly RECORDS_FILE="$DATA_DIR/personal_records.json"
readonly SETTINGS_FILE="$DATA_DIR/settings.conf"
readonly GOALS_FILE="$DATA_DIR/goals.json"
readonly BACKUP_DIR="$DATA_DIR/backups"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Global state
CURRENT_WORKOUT_SESSION=""
WORKOUT_IN_PROGRESS=false

# Exercise definitions with progression levels
declare -A EXERCISES=(
    ["pushups"]="Push-ups"
    ["pullups"]="Pull-ups"
    ["squats"]="Squats"
    ["lunges"]="Lunges"
    ["planks"]="Planks (seconds)"
    ["burpees"]="Burpees"
    ["situps"]="Sit-ups"
    ["jumping_jacks"]="Jumping Jacks"
    ["mountain_climbers"]="Mountain Climbers"
    ["wall_sits"]="Wall Sits (seconds)"
)

# Workout programs
declare -A PROGRAMS=(
    ["beginner"]="Beginner Full Body"
    ["strength"]="Strength Focus"
    ["cardio"]="Cardio Blast"
    ["core"]="Core Crusher"
    ["custom"]="Custom Workout"
)

# Cleanup function called on exit
cleanup_on_exit() {
    local exit_code=$?

    # If workout was in progress, save state
    if [[ "$WORKOUT_IN_PROGRESS" == true ]]; then
        echo ""
        echo -e "${YELLOW}Saving workout progress...${NC}"
        # Any cleanup needed for interrupted workout
    fi

    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}Session ended unexpectedly${NC}" >&2
    fi

    exit $exit_code
}

# Set up trap handlers
trap cleanup_on_exit EXIT
trap 'echo -e "\n${YELLOW}Workout interrupted. Data saved.${NC}"; exit 130' INT TERM

# Portable date function
get_date() {
    date +%Y-%m-%d
}

get_datetime() {
    date +"%Y-%m-%d %H:%M"
}

# Get date N days ago (portable)
get_date_ago() {
    local days=$1
    if date -v-${days}d +%Y-%m-%d 2>/dev/null; then
        # BSD date (macOS)
        date -v-${days}d +%Y-%m-%d
    else
        # GNU date (Linux)
        date -d "$days days ago" +%Y-%m-%d
    fi
}

# Input validation functions
validate_number() {
    local input="$1"
    local min="${2:-1}"
    local max="${3:-99999}"

    if [[ ! "$input" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    if [[ $input -lt $min || $input -gt $max ]]; then
        return 1
    fi

    return 0
}

validate_choice() {
    local choice="$1"
    local min="$2"
    local max="$3"

    validate_number "$choice" "$min" "$max"
}

# Initialize data directory and files
init_data() {
    mkdir -p "$DATA_DIR"
    mkdir -p "$BACKUP_DIR"

    if [[ ! -f "$HISTORY_FILE" ]]; then
        echo "Date,Exercise,Reps/Time,Sets,Notes" > "$HISTORY_FILE"
    fi

    if [[ ! -f "$RECORDS_FILE" ]]; then
        echo "{}" > "$RECORDS_FILE"
    fi

    if [[ ! -f "$GOALS_FILE" ]]; then
        echo "{}" > "$GOALS_FILE"
    fi

    if [[ ! -f "$SETTINGS_FILE" ]]; then
        cat > "$SETTINGS_FILE" << EOF
# Home Gym Settings
VOICE_ENABLED=true
DEFAULT_REST_TIME=60
MOTIVATION_ENABLED=true
STREAK_GOAL=30
AUTO_BACKUP=true
EOF
    fi

    source "$SETTINGS_FILE"

    # Auto backup if enabled
    if [[ "${AUTO_BACKUP:-true}" == "true" ]]; then
        auto_backup
    fi
}

# Automatic backup function
auto_backup() {
    # Keep daily backups for last 7 days
    local backup_file="$BACKUP_DIR/backup_$(get_date).tar.gz"

    # Only backup once per day
    if [[ ! -f "$backup_file" ]]; then
        tar -czf "$backup_file" -C "$DATA_DIR" \
            --exclude='backups' \
            workout_history.csv personal_records.json goals.json settings.conf 2>/dev/null || true

        # Clean old backups (keep last 7 days)
        find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    fi
}

# Voice feedback function
speak() {
    if [[ "$VOICE_ENABLED" == "true" ]]; then
        case $(uname) in
            Darwin) say "$1" > /dev/null 2>&1 ;;
            Linux)  espeak "$1" > /dev/null 2>&1 ;;
        esac
    fi
}

# Welcome screen with ASCII art
show_welcome() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║                    🏠 HOME GYM TRACKER 🏠                ║
    ║                                                           ║
    ║        💪 Build Strength • Track Progress • Stay Fit      ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Show streak and motivation
    local streak=$(get_current_streak)
    if [[ $streak -gt 0 ]]; then
        echo -e "${GREEN}🔥 Current streak: $streak days!${NC}"
    fi
    
    if [[ "$MOTIVATION_ENABLED" == "true" ]]; then
        show_daily_motivation
    fi
    
    echo ""
    sleep 2
}

# Daily motivation quotes
show_daily_motivation() {
    local quotes=(
        "Every rep counts! 💪"
        "Consistency beats perfection! 🎯"
        "Your only limit is you! 🚀"
        "Strong body, strong mind! 🧠"
        "Progress over perfection! 📈"
        "Champions train at home too! 🏆"
        "Small steps, big results! 👟"
        "Your future self will thank you! ⭐"
    )
    
    local quote_index=$(($(date +%j) % ${#quotes[@]}))
    echo -e "${YELLOW}💡 ${quotes[$quote_index]}${NC}"
}

# Rest timer between sets
rest_timer() {
    local duration="${1:-$DEFAULT_REST_TIME}"

    echo ""
    echo -e "${YELLOW}Rest period: $duration seconds${NC}"
    echo -e "${CYAN}Press ENTER to skip rest...${NC}"

    for ((i=duration; i>0; i--)); do
        printf "\r${WHITE}Rest time remaining: %02d:%02d${NC}" $((i/60)) $((i%60))

        # Check if user wants to skip
        if read -t 1 -n 1; then
            echo ""
            echo -e "${GREEN}Rest skipped!${NC}"
            return
        fi

        # Voice callouts
        case $i in
            30) speak "Thirty seconds rest remaining" ;;
            10) speak "Ten seconds!" ;;
            3) speak "Three!" ;;
        esac
    done

    printf "\r${GREEN}Rest complete! Get ready!${NC}\n"
    speak "Rest complete!"
    sleep 1
}

# Get current workout streak
get_current_streak() {
    local streak=0
    local current_date=$(get_date)

    if [[ -f "$HISTORY_FILE" ]]; then
        # Count consecutive days with workouts
        local last_dates=$(tail -n +2 "$HISTORY_FILE" | cut -d',' -f1 | cut -d' ' -f1 | sort -u | tail -30)
        local check_date=$current_date

        for i in {0..29}; do
            if echo "$last_dates" | grep -q "$check_date"; then
                ((streak++))
                check_date=$(get_date_ago $((i+1)))
            else
                break
            fi
        done
    fi

    echo $streak
}

# Main menu
show_main_menu() {
    clear
    echo -e "${WHITE}═══════ HOME GYM MAIN MENU ═══════${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} 🏋️  Start Workout"
    echo -e "${GREEN}2.${NC} 📊  View Progress & Stats"
    echo -e "${GREEN}3.${NC} 🏆  Personal Records"
    echo -e "${GREEN}4.${NC} 📅  Workout History"
    echo -e "${GREEN}5.${NC} 📋  Workout Programs"
    echo -e "${GREEN}6.${NC} 🎯  Goals"
    echo -e "${GREEN}7.${NC} 💾  Export Data"
    echo -e "${GREEN}8.${NC} ⚙️   Settings"
    echo -e "${GREEN}9.${NC} ❓  Exercise Guide"
    echo -e "${GREEN}0.${NC} 🚪  Exit"
    echo ""
    echo -e -n "${CYAN}Choose an option (0-9): ${NC}"
}

# Exercise selection menu
select_exercise() {
    clear
    echo -e "${WHITE}═══════ SELECT EXERCISE ═══════${NC}"
    echo ""
    
    local i=1
    local exercise_keys=()
    for key in "${!EXERCISES[@]}"; do
        exercise_keys+=("$key")
    done
    
    # Sort exercises alphabetically
    IFS=$'\n' exercise_keys=($(sort <<<"${exercise_keys[*]}"))
    
    for key in "${exercise_keys[@]}"; do
        echo -e "${GREEN}$i.${NC} ${EXERCISES[$key]}"
        ((i++))
    done
    
    echo ""
    echo -e -n "${CYAN}Choose exercise (1-${#exercise_keys[@]}): ${NC}"
    
    local choice
    read choice
    
    if [[ $choice -ge 1 && $choice -le ${#exercise_keys[@]} ]]; then
        local selected_key="${exercise_keys[$((choice-1))]}"
        start_exercise "$selected_key"
    else
        echo -e "${RED}Invalid choice!${NC}"
        sleep 2
        select_exercise
    fi
}

# Start an exercise session
start_exercise() {
    local exercise="$1"
    local exercise_name="${EXERCISES[$exercise]}"

    clear
    echo -e "${WHITE}═══════ ${exercise_name^^} WORKOUT ═══════${NC}"
    echo ""

    # Get current max/goal for this exercise
    local current_max=$(get_exercise_record "$exercise")
    if [[ $current_max -gt 0 ]]; then
        echo -e "${BLUE}Your current record: $current_max${NC}"
    else
        echo -e "${YELLOW}First time doing $exercise_name? Let's set a baseline!${NC}"
    fi

    echo ""
    echo -e -n "${CYAN}How many reps/seconds per set? ${NC}"
    local target
    read target

    if ! validate_number "$target" 1 10000; then
        echo -e "${RED}Please enter a valid number (1-10000)!${NC}"
        sleep 2
        start_exercise "$exercise"
        return
    fi

    echo -e -n "${CYAN}How many sets? ${NC}"
    local num_sets
    read num_sets

    if ! validate_number "$num_sets" 1 20; then
        echo -e "${RED}Please enter a valid number of sets (1-20)!${NC}"
        sleep 2
        start_exercise "$exercise"
        return
    fi

    # Confirm and start
    echo ""
    echo -e "${GREEN}Workout Plan:${NC}"
    echo -e "  ${num_sets} sets of ${target} ${exercise_name}"
    echo -e "  Rest: ${DEFAULT_REST_TIME} seconds between sets"
    echo ""
    echo -e -n "${CYAN}Ready to start? (y/n): ${NC}"
    local ready
    read ready

    if [[ $ready == "y" || $ready == "Y" ]]; then
        WORKOUT_IN_PROGRESS=true
        perform_multi_set_exercise "$exercise" "$target" "$num_sets"
        WORKOUT_IN_PROGRESS=false
    else
        select_exercise
    fi
}

# Perform multiple sets of an exercise
perform_multi_set_exercise() {
    local exercise="$1"
    local target="$2"
    local num_sets="$3"
    local exercise_name="${EXERCISES[$exercise]}"
    local total_reps=0

    for ((set=1; set<=num_sets; set++)); do
        clear
        echo -e "${WHITE}═══════ SET $set of $num_sets ═══════${NC}"
        echo -e "${GREEN}Exercise: ${exercise_name}${NC}"
        echo -e "${GREEN}Target: ${target}${NC}"
        echo ""

        # Pre-workout countdown
        echo -e "${YELLOW}Get ready! Starting in...${NC}"
        for i in {3..1}; do
            echo -e "${WHITE}$i${NC}"
            speak "$i"
            sleep 1
        done

        echo -e "${GREEN}GO! GO! GO!${NC}"
        speak "Go!"

        # Timer for time-based exercises
        if [[ $exercise == "planks" || $exercise == "wall_sits" ]]; then
            countdown_timer "$target" "$exercise_name"
            local actual=$target
        else
            # Rep-based exercises
            echo ""
            echo -e "${GREEN}Perform $target $exercise_name${NC}"
            echo -e "${CYAN}Press ENTER when you're done...${NC}"
            read

            # Ask how many completed
            echo -e -n "${CYAN}How many did you complete? ${NC}"
            local actual
            read actual

            if ! validate_number "$actual" 0 10000; then
                actual=$target
            fi
        fi

        total_reps=$((total_reps + actual))

        # Log this set
        log_workout "$exercise" "$actual" "1" "Set $set of $num_sets"

        # Check for PR on this set
        check_personal_record "$exercise" "$actual"

        # Rest between sets (except after last set)
        if [[ $set -lt $num_sets ]]; then
            rest_timer
        fi
    done

    # Post-workout summary
    echo ""
    echo -e "${GREEN}🎉 Workout Complete! 🎉${NC}"
    echo -e "${WHITE}Total reps/time: $total_reps${NC}"
    echo ""

    # Optional notes for the entire workout
    echo -e -n "${CYAN}Any notes about this workout? (optional): ${NC}"
    local notes
    read notes

    if [[ -n "$notes" ]]; then
        log_workout "$exercise" "$total_reps" "$num_sets" "Workout complete: $notes"
    fi

    echo -e "${CYAN}Press ENTER to continue...${NC}"
    read
}

# Perform the exercise with countdown and motivation
perform_exercise() {
    local exercise="$1"
    local target="$2"
    local exercise_name="${EXERCISES[$exercise]}"
    
    # Pre-workout countdown
    echo ""
    echo -e "${YELLOW}Get ready! Starting in...${NC}"
    for i in {3..1}; do
        echo -e "${WHITE}$i${NC}"
        speak "$i"
        sleep 1
    done
    
    echo -e "${GREEN}GO! GO! GO!${NC}"
    speak "Go!"
    
    # Timer for time-based exercises
    if [[ $exercise == "planks" || $exercise == "wall_sits" ]]; then
        countdown_timer "$target" "$exercise_name"
    else
        # Rep-based exercises
        echo ""
        echo -e "${GREEN}Perform $target $exercise_name${NC}"
        echo -e "${CYAN}Press ENTER when you're done...${NC}"
        read
    fi
    
    # Post-workout questions
    post_workout_questions "$exercise" "$target"
}

# Countdown timer for time-based exercises
countdown_timer() {
    local duration="$1"
    local exercise_name="$2"
    
    echo ""
    echo -e "${GREEN}Hold that $exercise_name!${NC}"
    
    for ((i=duration; i>0; i--)); do
        printf "\r${WHITE}Time remaining: %02d:%02d${NC}" $((i/60)) $((i%60))
        
        # Motivational callouts
        case $i in
            $((duration/2))) speak "Halfway there! Keep going!" ;;
            30) speak "Thirty seconds left!" ;;
            10) speak "Ten seconds!" ;;
            5) speak "Five!" ;;
            3) speak "Three!" ;;
            2) speak "Two!" ;;
            1) speak "One!" ;;
        esac
        
        sleep 1
    done
    
    printf "\r${GREEN}Time's up! Well done! 🎉${NC}\n"
    speak "Time's up! Excellent work!"
}

# Post-workout questions and logging
post_workout_questions() {
    local exercise="$1"
    local target="$2"
    local exercise_name="${EXERCISES[$exercise]}"
    
    echo ""
    echo -e "${GREEN}Great job! 🎉${NC}"
    echo ""
    
    # Ask how many they actually completed
    echo -e -n "${CYAN}How many $exercise_name did you actually complete? ${NC}"
    local actual
    read actual
    
    if [[ ! $actual =~ ^[0-9]+$ ]]; then
        actual=$target
    fi
    
    # Ask for difficulty rating
    echo -e -n "${CYAN}How difficult was this? (1=Easy, 5=Maximum effort): ${NC}"
    local difficulty
    read difficulty
    
    # Optional notes
    echo -e -n "${CYAN}Any notes about this workout? (optional): ${NC}"
    local notes
    read notes
    
    # Log the workout
    log_workout "$exercise" "$actual" "1" "$notes"
    
    # Check for new personal record
    check_personal_record "$exercise" "$actual"
    
    # Show encouragement
    show_workout_summary "$exercise" "$actual" "$target" "$difficulty"
}

# Log workout to history
log_workout() {
    local exercise="$1"
    local reps="$2"
    local sets="$3"
    local notes="$4"
    local date=$(date +%Y-%m-%d)
    local time=$(date +%H:%M)
    
    echo "$date $time,${EXERCISES[$exercise]},$reps,$sets,$notes" >> "$HISTORY_FILE"
}

# Check and update personal records
check_personal_record() {
    local exercise="$1"
    local reps="$2"
    local current_record=$(get_exercise_record "$exercise")
    
    if [[ $reps -gt $current_record ]]; then
        update_personal_record "$exercise" "$reps"
        echo ""
        echo -e "${YELLOW}🎉 NEW PERSONAL RECORD! 🎉${NC}"
        echo -e "${GREEN}Previous: $current_record → New: $reps${NC}"
        speak "New personal record!"
        sleep 3
    fi
}

# Get exercise record from records file
get_exercise_record() {
    local exercise="$1"
    
    if [[ -f "$RECORDS_FILE" ]]; then
        # Simple grep approach for bash compatibility
        local record=$(grep "\"$exercise\":" "$RECORDS_FILE" 2>/dev/null | sed 's/.*: *\([0-9]*\).*/\1/')
        echo "${record:-0}"
    else
        echo "0"
    fi
}

# Update personal record
update_personal_record() {
    local exercise="$1"
    local new_record="$2"
    local date=$(date +%Y-%m-%d)
    
    # Simple JSON update for bash compatibility
    if grep -q "\"$exercise\":" "$RECORDS_FILE" 2>/dev/null; then
        sed -i "s/\"$exercise\": *[0-9]*/\"$exercise\": $new_record/" "$RECORDS_FILE"
    else
        # Add new record
        if [[ $(wc -l < "$RECORDS_FILE") -eq 1 ]] && grep -q "^{}$" "$RECORDS_FILE"; then
            echo "{\"$exercise\": $new_record}" > "$RECORDS_FILE"
        else
            sed -i 's/}$/,/' "$RECORDS_FILE"
            echo "\"$exercise\": $new_record}" >> "$RECORDS_FILE"
        fi
    fi
}

# Show workout summary
show_workout_summary() {
    local exercise="$1"
    local actual="$2"
    local target="$3"
    local difficulty="$4"
    
    clear
    echo -e "${WHITE}═══════ WORKOUT SUMMARY ═══════${NC}"
    echo ""
    echo -e "${GREEN}Exercise:${NC} ${EXERCISES[$exercise]}"
    echo -e "${GREEN}Target:${NC} $target"
    echo -e "${GREEN}Completed:${NC} $actual"
    
    if [[ $actual -ge $target ]]; then
        echo -e "${GREEN}Result: 🎯 Target achieved!${NC}"
        speak "Target achieved! Excellent work!"
    else
        echo -e "${YELLOW}Result: 💪 Good effort! Try again next time.${NC}"
    fi
    
    echo -e "${GREEN}Difficulty:${NC} $difficulty/5"
    echo ""
    
    # Suggestions based on performance
    if [[ $actual -ge $target && $difficulty -le 2 ]]; then
        echo -e "${CYAN}💡 Tip: That seemed easy! Try increasing your target next time.${NC}"
    elif [[ $difficulty -ge 4 ]]; then
        echo -e "${CYAN}💡 Tip: Great intensity! Make sure to rest and recover.${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Press ENTER to continue...${NC}"
    read
}

# ASCII progress chart
draw_progress_chart() {
    local exercise="$1"
    local days="${2:-30}"

    echo -e "${WHITE}═══════ $exercise Progress (Last $days days) ═══════${NC}"
    echo ""

    # Get data for last N days
    local recent_date=$(get_date_ago $days)
    local data=$(tail -n +2 "$HISTORY_FILE" | grep "$exercise" | awk -F',' -v date="$recent_date" '$1 >= date {print $1" "$3}' | awk '{date=$1; reps+=$2} END {for (d in date) print d, reps}' | sort)

    if [[ -z "$data" ]]; then
        echo -e "${YELLOW}No data available for $exercise in the last $days days${NC}"
        return
    fi

    # Find max for scaling
    local max_reps=$(echo "$data" | awk '{if($2>max) max=$2} END {print max}')
    local chart_width=50

    echo "$data" | while read date reps; do
        local bar_length=$((reps * chart_width / max_reps))
        if [[ $bar_length -lt 1 && $reps -gt 0 ]]; then
            bar_length=1
        fi

        local bar=$(printf '%*s' "$bar_length" | tr ' ' '█')
        printf "${CYAN}%-12s${NC} ${GREEN}%-50s${NC} ${WHITE}%s${NC}\n" "$date" "$bar" "$reps"
    done

    echo ""
}

# View progress and statistics
show_progress() {
    clear
    echo -e "${WHITE}═══════ PROGRESS & STATISTICS ═══════${NC}"
    echo ""

    if [[ ! -s "$HISTORY_FILE" ]] || [[ $(wc -l < "$HISTORY_FILE") -le 1 ]]; then
        echo -e "${YELLOW}No workout data yet. Start exercising to see your progress!${NC}"
        echo ""
        echo -e "${CYAN}Press ENTER to continue...${NC}"
        read
        return
    fi

    # Overall statistics
    local total_workouts=$(tail -n +2 "$HISTORY_FILE" | wc -l)
    local current_streak=$(get_current_streak)
    local total_days=$(tail -n +2 "$HISTORY_FILE" | cut -d',' -f1 | cut -d' ' -f1 | sort -u | wc -l)

    echo -e "${GREEN}📊 Overall Statistics:${NC}"
    echo -e "   Total workouts: $total_workouts"
    echo -e "   Active days: $total_days"
    echo -e "   Current streak: $current_streak days"
    echo ""

    # Recent activity (last 7 days)
    echo -e "${GREEN}📅 Recent Activity (Last 7 days):${NC}"
    local recent_date=$(get_date_ago 7)
    local recent_workouts=$(tail -n +2 "$HISTORY_FILE" | awk -F',' -v date="$recent_date" '$1 >= date' | wc -l)
    echo -e "   Workouts completed: $recent_workouts"
    echo ""

    # Weekly comparison
    echo -e "${GREEN}📈 Week-over-Week:${NC}"
    local this_week=$(tail -n +2 "$HISTORY_FILE" | awk -F',' -v date="$(get_date_ago 7)" '$1 >= date' | wc -l)
    local last_week=$(tail -n +2 "$HISTORY_FILE" | awk -F',' -v date1="$(get_date_ago 14)" -v date2="$(get_date_ago 7)" '$1 >= date1 && $1 < date2' | wc -l)

    if [[ $last_week -gt 0 ]]; then
        local diff=$((this_week - last_week))
        if [[ $diff -gt 0 ]]; then
            echo -e "   ${GREEN}▲ +$diff workouts vs last week!${NC}"
        elif [[ $diff -lt 0 ]]; then
            echo -e "   ${RED}▼ $diff workouts vs last week${NC}"
        else
            echo -e "   ${YELLOW}= Same as last week${NC}"
        fi
    fi
    echo ""

    # Exercise breakdown
    echo -e "${GREEN}🏋️  Top Exercises:${NC}"
    tail -n +2 "$HISTORY_FILE" | cut -d',' -f2 | sort | uniq -c | sort -nr | head -5 | while read count exercise; do
        echo -e "   $exercise: $count sessions"
    done

    echo ""
    echo -e "${CYAN}Press ENTER for detailed charts...${NC}"
    read

    # Show progress charts for top exercises
    clear
    local top_exercise=$(tail -n +2 "$HISTORY_FILE" | cut -d',' -f2 | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
    if [[ -n "$top_exercise" ]]; then
        draw_progress_chart "$top_exercise" 14
    fi

    echo ""
    echo -e "${CYAN}Press ENTER to continue...${NC}"
    read
}

# View personal records
show_records() {
    clear
    echo -e "${WHITE}═══════ PERSONAL RECORDS 🏆 ═══════${NC}"
    echo ""
    
    if [[ ! -f "$RECORDS_FILE" ]] || grep -q "^{}$" "$RECORDS_FILE"; then
        echo -e "${YELLOW}No personal records yet. Start working out to set some records!${NC}"
        echo ""
        echo -e "${CYAN}Press ENTER to continue...${NC}"
        read
        return
    fi
    
    # Display all records
    for exercise in "${!EXERCISES[@]}"; do
        local record=$(get_exercise_record "$exercise")
        if [[ $record -gt 0 ]]; then
            echo -e "${GREEN}🏆 ${EXERCISES[$exercise]}:${NC} $record"
        fi
    done
    
    echo ""
    echo -e "${CYAN}Press ENTER to continue...${NC}"
    read
}

# View workout history
show_history() {
    clear
    echo -e "${WHITE}═══════ WORKOUT HISTORY 📅 ═══════${NC}"
    echo ""
    
    if [[ ! -s "$HISTORY_FILE" ]] || [[ $(wc -l < "$HISTORY_FILE") -le 1 ]]; then
        echo -e "${YELLOW}No workout history yet.${NC}"
        echo ""
        echo -e "${CYAN}Press ENTER to continue...${NC}"
        read
        return
    fi
    
    echo -e "${GREEN}Recent workouts:${NC}"
    echo ""
    
    # Show last 20 workouts
    tail -n 20 "$HISTORY_FILE" | tail -n +2 | while IFS=',' read -r datetime exercise reps sets notes; do
        echo -e "${CYAN}$datetime${NC} - ${GREEN}$exercise${NC}: $reps reps"
        if [[ -n "$notes" ]]; then
            echo -e "   📝 $notes"
        fi
        echo ""
    done
    
    echo -e "${CYAN}Press ENTER to continue...${NC}"
    read
}

# Workout Programs
show_programs() {
    clear
    echo -e "${WHITE}═══════ WORKOUT PROGRAMS 📋 ═══════${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Beginner Full Body (3 exercises)"
    echo -e "${GREEN}2.${NC} Strength Focus (4 exercises)"
    echo -e "${GREEN}3.${NC} Cardio Blast (5 exercises)"
    echo -e "${GREEN}4.${NC} Core Crusher (4 exercises)"
    echo -e "${GREEN}5.${NC} Back to main menu"
    echo ""
    echo -e -n "${CYAN}Choose program (1-5): ${NC}"

    local choice
    read choice

    case $choice in
        1) run_program "beginner" ;;
        2) run_program "strength" ;;
        3) run_program "cardio" ;;
        4) run_program "core" ;;
        5) return ;;
        *) echo -e "${RED}Invalid choice!${NC}"; sleep 1; show_programs ;;
    esac
}

# Run a workout program
run_program() {
    local program="$1"

    case $program in
        "beginner")
            echo -e "${GREEN}Starting Beginner Full Body Program!${NC}"
            perform_program_exercise "pushups" 10 3
            perform_program_exercise "squats" 15 3
            perform_program_exercise "planks" 30 2
            ;;
        "strength")
            echo -e "${GREEN}Starting Strength Focus Program!${NC}"
            perform_program_exercise "pushups" 15 4
            perform_program_exercise "pullups" 5 3
            perform_program_exercise "squats" 20 4
            perform_program_exercise "lunges" 12 3
            ;;
        "cardio")
            echo -e "${GREEN}Starting Cardio Blast Program!${NC}"
            perform_program_exercise "burpees" 10 3
            perform_program_exercise "jumping_jacks" 30 3
            perform_program_exercise "mountain_climbers" 20 3
            perform_program_exercise "squats" 20 2
            perform_program_exercise "pushups" 10 2
            ;;
        "core")
            echo -e "${GREEN}Starting Core Crusher Program!${NC}"
            perform_program_exercise "planks" 45 3
            perform_program_exercise "situps" 20 3
            perform_program_exercise "mountain_climbers" 25 3
            perform_program_exercise "burpees" 10 2
            ;;
    esac

    echo ""
    echo -e "${GREEN}🎉 Program Complete! Great work! 🎉${NC}"
    speak "Program complete! Excellent work!"
    echo ""
    echo -e "${CYAN}Press ENTER to continue...${NC}"
    read
}

# Perform exercise as part of a program
perform_program_exercise() {
    local exercise="$1"
    local reps="$2"
    local sets="$3"

    perform_multi_set_exercise "$exercise" "$reps" "$sets"
}

# Goals Management
show_goals() {
    clear
    echo -e "${WHITE}═══════ GOALS 🎯 ═══════${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} View current goals"
    echo -e "${GREEN}2.${NC} Set new goal"
    echo -e "${GREEN}3.${NC} Mark goal as complete"
    echo -e "${GREEN}4.${NC} Back to main menu"
    echo ""
    echo -e -n "${CYAN}Choose option (1-4): ${NC}"

    local choice
    read choice

    case $choice in
        1) view_goals ;;
        2) set_goal ;;
        3) complete_goal ;;
        4) return ;;
        *) echo -e "${RED}Invalid choice!${NC}"; sleep 1; show_goals ;;
    esac
}

# View goals
view_goals() {
    clear
    echo -e "${WHITE}═══════ YOUR GOALS 🎯 ═══════${NC}"
    echo ""

    if [[ ! -f "$GOALS_FILE" ]] || grep -q "^{}$" "$GOALS_FILE" 2>/dev/null; then
        echo -e "${YELLOW}No goals set yet. Set some goals to stay motivated!${NC}"
    else
        # Simple parsing for bash compatibility
        grep -o '"[^"]*": *"[^"]*"' "$GOALS_FILE" 2>/dev/null | while IFS=': ' read -r exercise goal; do
            exercise=$(echo "$exercise" | tr -d '"')
            goal=$(echo "$goal" | tr -d '"')
            echo -e "${GREEN}🎯 ${EXERCISES[$exercise]:-$exercise}:${NC} $goal"
        done
    fi

    echo ""
    echo -e "${CYAN}Press ENTER to continue...${NC}"
    read
    show_goals
}

# Set a goal
set_goal() {
    clear
    echo -e "${WHITE}═══════ SET NEW GOAL 🎯 ═══════${NC}"
    echo ""

    # Select exercise
    echo -e "${GREEN}Select exercise for goal:${NC}"
    local i=1
    local exercise_keys=()
    for key in "${!EXERCISES[@]}"; do
        exercise_keys+=("$key")
    done

    IFS=$'\n' exercise_keys=($(sort <<<"${exercise_keys[*]}"))

    for key in "${exercise_keys[@]}"; do
        echo -e "${GREEN}$i.${NC} ${EXERCISES[$key]}"
        ((i++))
    done

    echo ""
    echo -e -n "${CYAN}Choose exercise (1-${#exercise_keys[@]}): ${NC}"
    local choice
    read choice

    if ! validate_choice "$choice" 1 "${#exercise_keys[@]}"; then
        echo -e "${RED}Invalid choice!${NC}"
        sleep 2
        set_goal
        return
    fi

    local exercise="${exercise_keys[$((choice-1))]}"

    echo -e -n "${CYAN}Enter your goal (e.g., '50 reps', 'Do 100 total'): ${NC}"
    local goal
    read goal

    # Save goal (simple JSON update)
    if grep -q "\"$exercise\":" "$GOALS_FILE" 2>/dev/null; then
        sed -i "s/\"$exercise\": *\"[^\"]*\"/\"$exercise\": \"$goal\"/" "$GOALS_FILE"
    else
        if grep -q "^{}$" "$GOALS_FILE"; then
            echo "{\"$exercise\": \"$goal\"}" > "$GOALS_FILE"
        else
            sed -i 's/}$/,/' "$GOALS_FILE"
            echo "\"$exercise\": \"$goal\"}" >> "$GOALS_FILE"
        fi
    fi

    echo -e "${GREEN}Goal set! 🎯${NC}"
    sleep 2
    show_goals
}

# Complete a goal
complete_goal() {
    echo -e "${GREEN}Goal completion tracking coming soon!${NC}"
    sleep 2
    show_goals
}

# Export data
export_data() {
    clear
    echo -e "${WHITE}═══════ EXPORT DATA 💾 ═══════${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Export to CSV"
    echo -e "${GREEN}2.${NC} Create backup"
    echo -e "${GREEN}3.${NC} Restore from backup"
    echo -e "${GREEN}4.${NC} Back to main menu"
    echo ""
    echo -e -n "${CYAN}Choose option (1-4): ${NC}"

    local choice
    read choice

    case $choice in
        1) export_to_csv ;;
        2) create_manual_backup ;;
        3) restore_backup ;;
        4) return ;;
        *) echo -e "${RED}Invalid choice!${NC}"; sleep 1; export_data ;;
    esac
}

# Export to CSV
export_to_csv() {
    local export_file="$HOME/home_gym_export_$(get_date).csv"

    cp "$HISTORY_FILE" "$export_file"

    echo ""
    echo -e "${GREEN}Data exported to: $export_file${NC}"
    echo ""
    echo -e "${CYAN}Press ENTER to continue...${NC}"
    read
    export_data
}

# Create manual backup
create_manual_backup() {
    local backup_file="$BACKUP_DIR/manual_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

    tar -czf "$backup_file" -C "$DATA_DIR" \
        --exclude='backups' \
        workout_history.csv personal_records.json goals.json settings.conf 2>/dev/null

    echo ""
    echo -e "${GREEN}Backup created: $backup_file${NC}"
    echo ""
    echo -e "${CYAN}Press ENTER to continue...${NC}"
    read
    export_data
}

# Restore from backup
restore_backup() {
    clear
    echo -e "${WHITE}═══════ RESTORE FROM BACKUP ═══════${NC}"
    echo ""

    # List available backups
    local backups=($(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))

    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No backups found.${NC}"
        echo ""
        echo -e "${CYAN}Press ENTER to continue...${NC}"
        read
        export_data
        return
    fi

    echo -e "${GREEN}Available backups:${NC}"
    local i=1
    for backup in "${backups[@]}"; do
        echo -e "${GREEN}$i.${NC} $(basename "$backup")"
        ((i++))
    done

    echo ""
    echo -e -n "${CYAN}Choose backup to restore (1-${#backups[@]}, 0 to cancel): ${NC}"
    local choice
    read choice

    if [[ $choice -eq 0 ]]; then
        export_data
        return
    fi

    if ! validate_choice "$choice" 1 "${#backups[@]}"; then
        echo -e "${RED}Invalid choice!${NC}"
        sleep 2
        restore_backup
        return
    fi

    local backup_file="${backups[$((choice-1))]}"

    echo ""
    echo -e "${RED}⚠️  WARNING: This will overwrite your current data!${NC}"
    echo -e -n "${CYAN}Type 'YES' to confirm: ${NC}"
    local confirm
    read confirm

    if [[ "$confirm" == "YES" ]]; then
        tar -xzf "$backup_file" -C "$DATA_DIR"
        echo -e "${GREEN}Backup restored successfully!${NC}"
    else
        echo -e "${YELLOW}Restore cancelled.${NC}"
    fi

    echo ""
    echo -e "${CYAN}Press ENTER to continue...${NC}"
    read
    export_data
}

# Change rest time
change_rest_time() {
    echo ""
    echo -e -n "${CYAN}Enter new default rest time (seconds, 1-300): ${NC}"
    local new_time
    read new_time

    if validate_number "$new_time" 1 300; then
        DEFAULT_REST_TIME=$new_time
        sed -i "s/DEFAULT_REST_TIME=.*/DEFAULT_REST_TIME=$DEFAULT_REST_TIME/" "$SETTINGS_FILE"
        echo -e "${GREEN}Rest time set to: $DEFAULT_REST_TIME seconds${NC}"
    else
        echo -e "${RED}Invalid time! Must be between 1-300 seconds${NC}"
    fi

    sleep 2
    show_settings
}

# Toggle motivation
toggle_motivation() {
    if [[ "$MOTIVATION_ENABLED" == "true" ]]; then
        MOTIVATION_ENABLED="false"
    else
        MOTIVATION_ENABLED="true"
    fi

    sed -i "s/MOTIVATION_ENABLED=.*/MOTIVATION_ENABLED=$MOTIVATION_ENABLED/" "$SETTINGS_FILE"
    echo -e "${GREEN}Motivation quotes set to: $MOTIVATION_ENABLED${NC}"
    sleep 2
    show_settings
}

# Settings menu
show_settings() {
    clear
    echo -e "${WHITE}═══════ SETTINGS ⚙️ ═══════${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Toggle voice feedback (Currently: $VOICE_ENABLED)"
    echo -e "${GREEN}2.${NC} Default rest time (Currently: $DEFAULT_REST_TIME seconds)"
    echo -e "${GREEN}3.${NC} Toggle motivation quotes (Currently: $MOTIVATION_ENABLED)"
    echo -e "${GREEN}4.${NC} Toggle auto-backup (Currently: ${AUTO_BACKUP:-true})"
    echo -e "${GREEN}5.${NC} Reset all data"
    echo -e "${GREEN}6.${NC} Back to main menu"
    echo ""
    echo -e -n "${CYAN}Choose option (1-6): ${NC}"

    local choice
    read choice

    case $choice in
        1) toggle_voice_feedback ;;
        2) change_rest_time ;;
        3) toggle_motivation ;;
        4) toggle_auto_backup ;;
        5) reset_data ;;
        6) return ;;
        *) echo -e "${RED}Invalid choice!${NC}"; sleep 1; show_settings ;;
    esac
}

# Toggle auto backup
toggle_auto_backup() {
    if [[ "${AUTO_BACKUP:-true}" == "true" ]]; then
        AUTO_BACKUP="false"
    else
        AUTO_BACKUP="true"
    fi

    if grep -q "AUTO_BACKUP=" "$SETTINGS_FILE"; then
        sed -i "s/AUTO_BACKUP=.*/AUTO_BACKUP=$AUTO_BACKUP/" "$SETTINGS_FILE"
    else
        echo "AUTO_BACKUP=$AUTO_BACKUP" >> "$SETTINGS_FILE"
    fi

    echo -e "${GREEN}Auto-backup set to: $AUTO_BACKUP${NC}"
    sleep 2
    show_settings
}

# Toggle voice feedback
toggle_voice_feedback() {
    if [[ "$VOICE_ENABLED" == "true" ]]; then
        VOICE_ENABLED="false"
    else
        VOICE_ENABLED="true"
    fi
    
    sed -i "s/VOICE_ENABLED=.*/VOICE_ENABLED=$VOICE_ENABLED/" "$SETTINGS_FILE"
    echo -e "${GREEN}Voice feedback set to: $VOICE_ENABLED${NC}"
    sleep 2
    show_settings
}

# Exercise guide
show_exercise_guide() {
    clear
    echo -e "${WHITE}═══════ EXERCISE GUIDE 📖 ═══════${NC}"
    echo ""
    
    cat << EOF
${GREEN}🏋️ BODYWEIGHT EXERCISES GUIDE:${NC}

${CYAN}Push-ups:${NC} Classic chest, shoulders, triceps exercise
${CYAN}Pull-ups:${NC} Great for back and biceps (needs bar/tree branch)
${CYAN}Squats:${NC} Lower body strength - quads, glutes, hamstrings
${CYAN}Lunges:${NC} Single-leg strength and balance
${CYAN}Planks:${NC} Core stability and strength
${CYAN}Burpees:${NC} Full-body cardio and strength
${CYAN}Sit-ups:${NC} Abdominal strength
${CYAN}Jumping Jacks:${NC} Cardio warm-up or workout
${CYAN}Mountain Climbers:${NC} Core and cardio combination
${CYAN}Wall Sits:${NC} Isometric leg strength

${YELLOW}💡 Tips:${NC}
• Focus on proper form over speed
• Start with easier variations if needed
• Rest 30-60 seconds between sets
• Stay hydrated during workouts
• Listen to your body and avoid injury

EOF
    
    echo -e "${CYAN}Press ENTER to continue...${NC}"
    read
}

# Reset all data
reset_data() {
    echo ""
    echo -e "${RED}⚠️  WARNING: This will delete ALL workout data!${NC}"
    echo -e -n "${CYAN}Are you sure? Type 'YES' to confirm: ${NC}"
    
    local confirm
    read confirm
    
    if [[ "$confirm" == "YES" ]]; then
        rm -f "$HISTORY_FILE" "$RECORDS_FILE"
        init_data
        echo -e "${GREEN}All data has been reset.${NC}"
    else
        echo -e "${YELLOW}Reset cancelled.${NC}"
    fi
    
    sleep 2
    show_settings
}

# Main program loop
main() {
    init_data
    show_welcome

    while true; do
        show_main_menu
        local choice
        read choice

        case $choice in
            1) select_exercise ;;
            2) show_progress ;;
            3) show_records ;;
            4) show_history ;;
            5) show_programs ;;
            6) show_goals ;;
            7) export_data ;;
            8) show_settings ;;
            9) show_exercise_guide ;;
            0) echo -e "${GREEN}Thanks for working out! Stay strong! 💪${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice!${NC}"; sleep 1 ;;
        esac
    done
}

# Run the program
main "$@"