#!/bin/bash


REPORT_NAME="Server_health_report"
OUTPUT_FILE="${REPORT_NAME// /_}.html"

# Print the current working directory and hostname
echo "Current working directory: $(pwd)"
echo "Hostname: $(hostname)"


# Banner
echo "╔═════════════════════════════════════════╗"
echo "║ health report by coldseven              ║"
echo "╚═════════════════════════════════════════╝"


# Function to generate HTML header
generate_html_header() {
    cat <<EOF
    <!DOCTYPE html>
    <html>
    <head>
        <title>Server Health Report</title>
        <style>
            body { font-family: Arial, sans-serif; }
            h1, h2 { color: #4CAF50; }
            pre { background-color: #f1f1f1; padding: 10px; }
        </style>
    </head>
    <body>
EOF
}


# Function to generate HTML footer
generate_html_footer() {
    cat <<EOF
    </body>
    </html>
EOF
}

# Function to check IP address
check_ip_address() {
    cat <<EOF
    <h2>IP Address</h2>
    <pre>
    $(ip addr show | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    </pre>
EOF
}


# Function to check DNS servers
check_dns_servers() {
    cat <<EOF
    <h2>DNS Servers</h2>
    <pre>
    $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
    </pre>
EOF
}


# Function to check DNS response time
check_dns_response_time() {
    local domain="google.com"
    local response_time=$(dig +time=1 +tries=1 "$domain" | grep "Query time" | awk '{print $4}')
    cat <<EOF
    <h2>DNS Response Time</h2>
    <pre>
    The response time for $domain is $response_time milliseconds.
    </pre>
EOF
}

# Function to check system load
check_system_load() {
    cat <<EOF
    <h2>System Load</h2>
    <pre>
    $(uptime)
    </pre>
EOF
}


# Function to check disk usage
check_disk_usage() {
    cat <<EOF
    <h2>Disk Usage</h2>
    <pre>
    $(df -h)
    </pre>
EOF
}

# Function to check network connections
check_network_connections() {
    cat <<EOF
    <h2>Network Connections</h2>
    <pre>
    $(netstat -antp)
    </pre>
EOF
}

# Function to check running processes
check_running_processes() {
    cat <<EOF
    <h2>Running Processes</h2>
    <pre>
    $(top -n 1)
    </pre>
EOF
}

# Function to check logs 
check_system_logs() {
    if [ -f "/var/log/messages" ]; then
        LOG_FILE="/var/log/messages"
    elif [ -f "/var/log/syslog" ]; then
        LOG_FILE="/var/log/syslog"
    else
        echo "Unable to locate system log file."
        return 1
    fi

    cat <<EOF
    <h2>System Logs</h2>
    <pre>
    $(tail -n 50 "$LOG_FILE")
    </pre>
EOF
}

# Function to check memory usage
check_memory_usage() {
    cat <<EOF
    <h2>Memory Usage</h2>
    <pre>
    $(free -h)
    </pre>
EOF
}

# Function to check CPU utilization
check_cpu_utilization() {
    cat <<EOF
    <h2>CPU Utilization</h2>
    <pre>
    $(top -bn1 | grep "Cpu(s)")
    </pre>
EOF
}

# Function to check open ports
check_open_ports() {
    cat <<EOF
    <h2>Open Ports</h2>
    <pre>
    $(netstat -antp | grep LISTEN)
    </pre>
EOF
}

# Function to check failed systemd services
check_failed_services() {
    cat <<EOF
    <h2>Failed Systemd Services</h2>
    <pre>
    $(systemctl --failed)
    </pre>
EOF
}



# Function to check web server logs
check_web_server_logs() {
    echo "<h2>Web Server Logs</h2>"

    if apache2 -v &>/dev/null; then
        echo "<h3>Apache Error Logs</h3>"
        if [ -f "/var/log/apache2/error.log" ]; then
            echo "<pre>"
            tail -n 50 /var/log/apache2/error.log
            echo "</pre>"
        else
            echo "<p>Apache error log file not found.</p>"
        fi
    else
        echo "<h3>Apache Error Logs</h3>"
        echo "<p>Apache is not installed on this system.</p>"
    fi

    if nginx -v &>/dev/null; then
        echo "<h3>Nginx Error Logs</h3>"
        if [ -f "/var/log/nginx/error.log" ]; then
            echo "<pre>"
            tail -n 50 /var/log/nginx/error.log
            echo "</pre>"
        else
            echo "<p>Nginx error log file not found.</p>"
        fi
    else
        echo "<h3>Nginx Error Logs</h3>"
        echo "<p>Nginx is not installed on this system.</p>"
    fi
}


# Function to check for firwalld status
check_firewalld_status() {
    if systemctl status firewalld &>/dev/null; then
        cat <<EOF
        <h2>Check Firewalld Status</h2>
        <pre>
        $(systemctl status firewalld)
        </pre>
EOF
    elif service ufw status &>/dev/null; then
        cat <<EOF
        <h2>Check Firewall Status</h2>
        <pre>
        $(service ufw status)
        </pre>
EOF
    else
        echo "Unable to determine firewall status. No suitable command found."
        return 1
    fi
}



# Function to check SELinux status
check_selinux_status() {
    if sestatus &>/dev/null; then
        cat <<EOF
        <h2>SELinux Status</h2>
        <pre>
        $(sestatus)
        </pre>
EOF
    else
        echo "<h2>SELinux Status</h2>"
        echo "<p>SELinux is not installed on this system.</p>"
    fi
}


# Generate HTML report
generate_html_header      >  $OUTPUT_FILE
check_system_load         >> $OUTPUT_FILE
check_ip_address          >> $OUTPUT_FILE
check_dns_servers         >> $OUTPUT_FILE
check_dns_response_time   >> $OUTPUT_FILE
check_disk_usage          >> $OUTPUT_FILE
check_network_connections >> $OUTPUT_FILE
check_running_processes   >> $OUTPUT_FILE
check_system_logs         >> $OUTPUT_FILE
check_memory_usage        >> $OUTPUT_FILE
check_cpu_utilization     >> $OUTPUT_FILE
check_open_ports          >> $OUTPUT_FILE
check_failed_services     >> $OUTPUT_FILE
check_web_server_logs     >> $OUTPUT_FILE
check_firewalld_status    >> $OUTPUT_FILE
check_selinux_status      >> $OUTPUT_FILE
generate_html_footer      >> $OUTPUT_FILE

echo "Server health report saved to $(pwd)"
