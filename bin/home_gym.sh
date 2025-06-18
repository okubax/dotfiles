#!/bin/bash
# home_gym.sh - Comprehensive Home Workout Tracker
# No equipment needed - bodyweight exercises only!

# Configuration
DATA_DIR="$HOME/.home_gym"
HISTORY_FILE="$DATA_DIR/workout_history.csv"
RECORDS_FILE="$DATA_DIR/personal_records.json"
SETTINGS_FILE="$DATA_DIR/settings.conf"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

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

# Initialize data directory and files
init_data() {
    mkdir -p "$DATA_DIR"
    
    if [[ ! -f "$HISTORY_FILE" ]]; then
        echo "Date,Exercise,Reps/Time,Sets,Notes" > "$HISTORY_FILE"
    fi
    
    if [[ ! -f "$RECORDS_FILE" ]]; then
        echo "{}" > "$RECORDS_FILE"
    fi
    
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        cat > "$SETTINGS_FILE" << EOF
# Home Gym Settings
VOICE_ENABLED=true
DEFAULT_REST_TIME=60
MOTIVATION_ENABLED=true
STREAK_GOAL=30
EOF
    fi
    
    source "$SETTINGS_FILE"
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

# Get current workout streak
get_current_streak() {
    local streak=0
    local current_date=$(date +%Y-%m-%d)
    
    if [[ -f "$HISTORY_FILE" ]]; then
        # Count consecutive days with workouts
        local last_dates=$(tail -n +2 "$HISTORY_FILE" | cut -d',' -f1 | sort -u | tail -30)
        local check_date=$current_date
        
        for i in {0..29}; do
            if echo "$last_dates" | grep -q "$check_date"; then
                ((streak++))
                check_date=$(date -d "$check_date - 1 day" +%Y-%m-%d 2>/dev/null || date -v-1d -j -f "%Y-%m-%d" "$check_date" +%Y-%m-%d 2>/dev/null)
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
    echo -e "${GREEN}6.${NC} ⚙️   Settings"
    echo -e "${GREEN}7.${NC} ❓  Exercise Guide"
    echo -e "${GREEN}8.${NC} 🚪  Exit"
    echo ""
    echo -e -n "${CYAN}Choose an option (1-8): ${NC}"
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
    echo -e -n "${CYAN}How many reps/seconds do you want to aim for? ${NC}"
    local target
    read target
    
    if [[ ! $target =~ ^[0-9]+$ ]] || [[ $target -lt 1 ]]; then
        echo -e "${RED}Please enter a valid number!${NC}"
        sleep 2
        start_exercise "$exercise"
        return
    fi
    
    # Confirm and start
    echo ""
    echo -e "${GREEN}Target: $target ${exercise_name}${NC}"
    echo -e -n "${CYAN}Ready to start? (y/n): ${NC}"
    local ready
    read ready
    
    if [[ $ready == "y" || $ready == "Y" ]]; then
        perform_exercise "$exercise" "$target"
    else
        select_exercise
    fi
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
    local recent_date=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null)
    local recent_workouts=$(tail -n +2 "$HISTORY_FILE" | awk -F',' -v date="$recent_date" '$1 >= date' | wc -l)
    echo -e "   Workouts completed: $recent_workouts"
    echo ""
    
    # Exercise breakdown
    echo -e "${GREEN}🏋️  Exercise Breakdown:${NC}"
    tail -n +2 "$HISTORY_FILE" | cut -d',' -f2 | sort | uniq -c | sort -nr | head -5 | while read count exercise; do
        echo -e "   $exercise: $count sessions"
    done
    
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

# Settings menu
show_settings() {
    clear
    echo -e "${WHITE}═══════ SETTINGS ⚙️ ═══════${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Toggle voice feedback (Currently: $VOICE_ENABLED)"
    echo -e "${GREEN}2.${NC} Default rest time (Currently: $DEFAULT_REST_TIME seconds)"
    echo -e "${GREEN}3.${NC} Toggle motivation quotes (Currently: $MOTIVATION_ENABLED)"
    echo -e "${GREEN}4.${NC} Reset all data"
    echo -e "${GREEN}5.${NC} Back to main menu"
    echo ""
    echo -e -n "${CYAN}Choose option (1-5): ${NC}"
    
    local choice
    read choice
    
    case $choice in
        1) toggle_voice_feedback ;;
        2) change_rest_time ;;
        3) toggle_motivation ;;
        4) reset_data ;;
        5) return ;;
        *) echo -e "${RED}Invalid choice!${NC}"; sleep 1; show_settings ;;
    esac
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
            5) echo "Programs feature coming soon!" && sleep 2 ;;
            6) show_settings ;;
            7) show_exercise_guide ;;
            8) echo -e "${GREEN}Thanks for working out! Stay strong! 💪${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice!${NC}"; sleep 1 ;;
        esac
    done
}

# Run the program
main "$@"