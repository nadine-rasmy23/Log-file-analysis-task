#!/bin/bash

# Check if log file is provided as argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <logfile>"
    exit 1
fi

LOGFILE=$1

# Check if log file exists
if [ ! -f "$LOGFILE" ]; then
    echo "Error: Log file $LOGFILE does not exist"
    exit 1
fi

# Create output file for results
OUTPUT_FILE="log_analysis_report.txt"
> $OUTPUT_FILE

# Function to print section headers
print_section() {
    echo "=====================================" | tee -a $OUTPUT_FILE
    echo "$1" | tee -a $OUTPUT_FILE
    echo "=====================================" | tee -a $OUTPUT_FILE
}

# 1. Request Counts
print_section "Request Counts"
total_requests=$(wc -l < "$LOGFILE")
get_requests=$(grep '"GET' "$LOGFILE" | wc -l)
post_requests=$(grep '"POST' "$LOGFILE" | wc -l)
echo "Total Requests: $total_requests" | tee -a $OUTPUT_FILE
echo "GET Requests: $get_requests" | tee -a $OUTPUT_FILE
echo "POST Requests: $post_requests" | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# 2. Unique IP Addresses
print_section "Unique IP Addresses"
unique_ips=$(awk '{print $1}' "$LOGFILE" | sort | uniq | wc -l)
echo "Total Unique IPs: $unique_ips" | tee -a $OUTPUT_FILE
echo "IP Address | GET Requests | POST Requests" | tee -a $OUTPUT_FILE
awk '{print $1}' "$LOGFILE" | sort | uniq | while read ip; do
    get_count=$(grep "$ip" "$LOGFILE" | grep '"GET' | wc -l)
    post_count=$(grep "$ip" "$LOGFILE" | grep '"POST' | wc -l)
    echo "$ip | $get_count | $post_count" | tee -a $OUTPUT_FILE
done
echo "" | tee -a $OUTPUT_FILE

# 3. Failure Requests
print_section "Failure Requests"
failed_requests=$(awk '$9 ~ /^[4-5][0-9][0-9]$/' "$LOGFILE" | wc -l)
failed_percentage=$(echo "scale=2; ($failed_requests / $total_requests) * 100" | bc)
echo "Failed Requests (4xx/5xx): $failed_requests" | tee -a $OUTPUT_FILE
echo "Failed Percentage: $failed_percentage%" | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# 4. Top User
print_section "Top User"
top_user=$(awk '{print $1}' "$LOGFILE" | sort | uniq -c | sort -nr | head -1)
top_user_ip=$(echo "$top_user" | awk '{print $2}')
top_user_count=$(echo "$top_user" | awk '{print $1}')
echo "Top User: $top_user_ip with $top_user_count requests" | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# 5. Daily Request Averages
print_section "Daily Request Averages"
days=$(awk -F'[' '{print $2}' "$LOGFILE" | awk -F':' '{print $1}' | sort | uniq | wc -l)
daily_avg=$(echo "scale=2; $total_requests / $days" | bc)
echo "Number of Days: $days" | tee -a $OUTPUT_FILE
echo "Average Daily Requests: $daily_avg" | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# 6. Failure Analysis (Days with Highest Failures)
print_section "Failure Analysis (Days with Highest Failures)"
awk '$9 ~ /^[4-5][0-9][0-9]$/ {print $4}' "$LOGFILE" | awk -F'[' '{print $2}' | awk -F':' '{print $1}' | sort | uniq -c | sort -nr | head -5 | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# 7. Requests by Hour
print_section "Requests by Hour"
awk -F'[' '{print $2}' "$LOGFILE" | awk -F':' '{print $2}' | sort | uniq -c | sort -n | awk '{print "Hour " $2 ": " $1 " requests"}' | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# 8. Request Trends
print_section "Request Trends"
echo "Check 'Requests by Hour' and 'Daily Request Averages' for patterns." | tee -a $OUTPUT_FILE
echo "High request hours indicate peak usage times." | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# 9. Status Codes Breakdown
print_section "Status Codes Breakdown"
awk '{print $9}' "$LOGFILE" | sort | uniq -c | sort -nr | awk '{print "Status " $2 ": " $1 " requests"}' | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# 10. Most Active User by Method
print_section "Most Active User by Method"
top_get_user=$(grep '"GET' "$LOGFILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -1)
top_get_ip=$(echo "$top_get_user" | awk '{print $2}')
top_get_count=$(echo "$top_get_user" | awk '{print $1}')
top_post_user=$(grep '"POST' "$LOGFILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -1)
top_post_ip=$(echo "$top_post_user" | awk '{print $2}')
top_post_count=$(echo "$top_post_user" | awk '{print $1}')
echo "Top GET User: $top_get_ip with $top_get_count GET requests" | tee -a $OUTPUT_FILE
echo "Top POST User: $top_post_ip with $top_post_count POST requests" | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# 11. Patterns in Failure Requests
print_section "Patterns in Failure Requests"
awk '$9 ~ /^[4-5][0-9][0-9]$/ {print $4}' "$LOGFILE" | awk -F'[' '{print $2}' | awk -F':' '{print $1":"$2}' | sort | uniq -c | sort -nr | head -5 | awk '{print "Day-Hour " $2 ": " $1 " failures"}' | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

echo "Analysis complete. Results saved to $OUTPUT_FILE"
